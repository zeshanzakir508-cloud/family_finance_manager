// lib/screens/settings/language_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';
  bool _isSaving = false;

  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
    {'code': 'ur', 'name': 'Urdu', 'flag': '🇵🇰', 'native': 'اردو'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'native': 'العربية'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷', 'native': 'Français'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸', 'native': 'Español'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪', 'native': 'Deutsch'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳', 'native': '中文'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵', 'native': '日本語'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳', 'native': 'हिन्दी'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹', 'native': 'Português'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  void _loadLanguage() {
    // TODO: Load from SharedPreferences
    _selectedLanguage = 'en';
  }

  Future<void> _saveLanguage() async {
    setState(() => _isSaving = true);

    try {
      // TODO: Save to SharedPreferences
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Language updated successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to save language: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveLanguage,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select your preferred language',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'The app will be displayed in this language',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ..._languages.map((language) {
              final isSelected = language['code'] == _selectedLanguage;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : isDark
                          ? Colors.grey[800]
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isDark
                            ? Colors.grey[700]!
                            : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Text(
                    language['flag'],
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    language['name'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  subtitle: Text(
                    language['native'],
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = language['code'];
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 24),

            CustomButton(
              onPressed: _isSaving ? null : _saveLanguage,
              text: 'Save Language',
              isLoading: _isSaving,
              type: ButtonType.primary,
              size: ButtonSize.large,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }
}
