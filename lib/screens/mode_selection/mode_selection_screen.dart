// lib/screens/mode_selection/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/mode_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/mode_card.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  AppMode _selectedMode = AppMode.personal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = context.read<ModeProvider>().currentMode;
  }

  Future<void> _continueWithMode() async {
    setState(() => _isLoading = true);

    try {
      // Save mode to provider
      context.read<ModeProvider>().setMode(
        _selectedMode == AppMode.personal ? 'personal' : 'family',
      );

      // Save mode to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mode_selected', true);

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header
              Column(
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.people,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Your Mode',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select how you want to manage your finances',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Mode Cards
              Expanded(
                child: Column(
                  children: [
                    ModeCard(
                      mode: AppMode.personal,
                      title: 'Personal Mode',
                      description: 'Manage your own finances independently',
                      icon: Icons.person,
                      isSelected: _selectedMode == AppMode.personal,
                      onTap: () {
                        setState(() {
                          _selectedMode = AppMode.personal;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ModeCard(
                      mode: AppMode.family,
                      title: 'Family Mode',
                      description: 'Manage finances together with your family',
                      icon: Icons.family_restroom,
                      isSelected: _selectedMode == AppMode.family,
                      onTap: () {
                        setState(() {
                          _selectedMode = AppMode.family;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Continue Button
              CustomButton(
                onPressed: _continueWithMode,
                text: 'Continue',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
              ),
              const SizedBox(height: 16),
              // Logout
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
