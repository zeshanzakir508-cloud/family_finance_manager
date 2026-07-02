import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme_mode') ?? 'system';
    });
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme);
    setState(() => _selectedTheme = theme);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme updated to ${theme.toUpperCase()}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Theme Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildThemeTile(
            icon: Icons.phone_android,
            title: 'System Default',
            subtitle: 'Follow device theme',
            value: 'system',
          ),
          _buildThemeTile(
            icon: Icons.light_mode,
            title: 'Light Mode',
            subtitle: 'Always use light theme',
            value: 'light',
          ),
          _buildThemeTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Always use dark theme',
            value: 'dark',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: _selectedTheme == value ? AppTheme.primaryColor : null,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: _selectedTheme == value
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () => _saveTheme(value),
      ),
    );
  }
}
