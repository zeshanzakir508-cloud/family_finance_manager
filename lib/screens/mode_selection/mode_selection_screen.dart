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

// ✅ ADDED: AppMode enum if not defined elsewhere
enum AppMode {
  personal,
  family,
}

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

  // ✅ ADDED: Load saved mode from provider
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
      // Save mode to provider
      final modeProvider = context.read<ModeProvider>();
      modeProvider.setMode(
        _selectedMode == AppMode.personal ? 'personal' : 'family',
      );

      // Save mode to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mode_selected', true);
      await prefs.setString('selected_mode', _selectedMode == AppMode.personal ? 'personal' : 'family');

      // ✅ ADDED: Check if user is authenticated
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) {
        throw Exception('User not authenticated. Please login again.');
      }

      // ✅ ADDED: Log the selected mode
      print('✅ Mode selected: ${_selectedMode == AppMode.personal ? 'Personal' : 'Family'}');
      print('✅ User: ${authProvider.user?.email ?? 'Unknown'}');
      print('✅ Role: ${authProvider.user?.role ?? 'Unknown'}');

      // Navigate to home
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
    final authProvider = context.watch<AuthProvider>();

    // ✅ ADDED: Show loading if auth is loading
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

    // ✅ ADDED: Show error if user is null
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
                  context.read<AuthProvider>().logout();
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
                  // ✅ ADDED: Show user info
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
