// lib/screens/mode_selection/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/mode_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
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
    _loadSavedMode();
  }

  void _loadSavedMode() {
    final modeProvider = context.read<ModeProvider>();
    final currentMode = modeProvider.currentMode;
    
    if (currentMode == 'family') {
      _selectedMode = AppMode.family;
    } else {
      _selectedMode = AppMode.personal;
    }
  }

  Future<void> _continueWithMode() async {
    setState(() => _isLoading = true);

    try {
      final modeProvider = context.read<ModeProvider>();
      modeProvider.setMode(
        _selectedMode == AppMode.personal ? 'personal' : 'family',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mode_selected', true);
      await prefs.setString('selected_mode', _selectedMode == AppMode.personal ? 'personal' : 'family');

      // ✅ FIXED: AuthProvider → AppAuthProvider
      final authProvider = context.read<AppAuthProvider>();
      if (!authProvider.isAuthenticated) {
        throw Exception('User not authenticated. Please login again.');
      }

      print('✅ Mode selected: ${_selectedMode == AppMode.personal ? 'Personal' : 'Family'}');
      print('✅ User: ${authProvider.user?.email ?? 'Unknown'}');
      print('✅ Role: ${authProvider.user?.role ?? 'Unknown'}');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('❌ Mode selection error: $e');
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
    // ✅ FIXED: AuthProvider → AppAuthProvider
    final authProvider = context.watch<AppAuthProvider>();

    if (authProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (authProvider.user == null && !authProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'User not found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login again',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // ✅ FIXED: AuthProvider → AppAuthProvider
                  context.read<AppAuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
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
                  const SizedBox(height: 8),
                  Text(
                    'Welcome, ${authProvider.user?.displayName ?? 'User'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 40),
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
              CustomButton(
                onPressed: _continueWithMode,
                text: 'Continue',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // ✅ FIXED: AuthProvider → AppAuthProvider
                  context.read<AppAuthProvider>().logout();
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
