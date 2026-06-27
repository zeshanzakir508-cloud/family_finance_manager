import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mode_provider.dart';
import '../../utils/app_theme.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String _selectedMode = 'personal';
  bool _rememberChoice = false;

  @override
  void initState() {
    super.initState();
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    if (modeProvider.rememberChoice) {
      _selectedMode = modeProvider.currentMode;
      _rememberChoice = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Family Finance Manager',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Select Your Mode',
                  style: AppTheme.subheadingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Mode Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        title: 'Personal Mode',
                        icon: Icons.person,
                        description: 'Manage your own finances',
                        mode: 'personal',
                        isSelected: _selectedMode == 'personal',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModeCard(
                        title: 'Family Mode',
                        icon: Icons.family_restroom,
                        description: 'Manage your family finances',
                        mode: 'family',
                        isSelected: _selectedMode == 'family',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Remember Choice
                Row(
                  children: [
                    Checkbox(
                      value: _rememberChoice,
                      onChanged: (value) {
                        setState(() {
                          _rememberChoice = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    Text(
                      'Remember my choice',
                      style: AppTheme.bodyStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _continue(modeProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required IconData icon,
    required String description,
    required String mode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _continue(ModeProvider modeProvider) {
    if (_selectedMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mode'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    modeProvider.setMode(_selectedMode, remember: _rememberChoice);

    if (_selectedMode == 'personal') {
      Navigator.pushReplacementNamed(context, '/personal-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/family-dashboard');
    }
  }
}
