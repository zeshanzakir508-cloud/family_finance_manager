// lib/screens/settings/theme_settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const ThemeSettingsScreen({super.key, this.onThemeChanged});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'system';
  String _initialTheme = 'system';
  bool _hasChanges = false;
  
  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debounceAction(VoidCallback action) {
    if (_isProcessing) return;
    _debounceTimer?.cancel();
    _isProcessing = true;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      action();
      _isProcessing = false;
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _selectedTheme = savedTheme;
      _initialTheme = savedTheme;
      _hasChanges = false;
    });
  }

  void _selectTheme(String theme) {
    _debounceAction(() {
      setState(() {
        _selectedTheme = theme;
        _hasChanges = _selectedTheme != _initialTheme;
      });
    });
  }

  Future<void> _saveTheme() async {
    _debounceAction(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _selectedTheme);
      setState(() {
        _initialTheme = _selectedTheme;
        _hasChanges = false;
      });
      
      await _applyTheme();
      
      if (widget.onThemeChanged != null) {
        widget.onThemeChanged!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme updated to ${_getThemeLabel(_selectedTheme)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, _selectedTheme);
      }
    });
  }

  Future<void> _applyTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _selectedTheme);
    
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _cancelChanges() {
    _debounceAction(() {
      if (_hasChanges) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved theme changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedTheme = _initialTheme;
                    _hasChanges = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme changes discarded'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context);
      }
    });
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'system': return 'System Default';
      case 'light': return 'Light Mode';
      case 'dark': return 'Dark Mode';
      default: return theme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Theme Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveTheme,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                _buildThemePreview(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildBottomButtons(),
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
    final isSelected = _selectedTheme == value;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? AppTheme.primaryColor 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
        onTap: () => _selectTheme(value),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildThemePreview() {
    final isDark = _selectedTheme == 'dark';
    
    final previewColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[800] : Colors.grey[100];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: previewColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Sample subtitle text',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Income: \$5,000',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Expense: \$2,000',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected: ${_getThemeLabel(_selectedTheme)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                Icon(
                  _selectedTheme == 'dark' 
                      ? Icons.dark_mode 
                      : (_selectedTheme == 'light' 
                          ? Icons.light_mode 
                          : Icons.phone_android),
                  color: Colors.blue,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _hasChanges ? _saveTheme : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasChanges 
                    ? AppTheme.primaryColor 
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_hasChanges ? 'Save Changes' : 'No Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
