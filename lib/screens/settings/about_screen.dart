// lib/screens/settings/about_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final String _appVersion = '2.0.0';
  final String _buildYear = '2026';

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        CustomSnackBar.show(
          context,
          'Could not open link',
          isError: true,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error opening link',
        isError: true,
      );
    }
  }

  Future<void> _contactSupport() async {
    final email = 'support@finfam.com';
    final subject = 'FinFam Support Request';
    final body = '''
Hello FinFam Team,

I need help with...

---
App Version: $_appVersion
User: ${context.read<AuthProvider>().user?.email ?? 'Not logged in'}
''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        CustomSnackBar.show(
          context,
          'No email app found',
          isError: true,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Could not open email',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About FinFam'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.people,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'FinFam',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Family Finance Manager',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Version $_appVersion ($_buildYear)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FinFam is your all-in-one family finance manager. '
                    'Track expenses, manage budgets, set financial goals, '
                    'and collaborate with family members - all in one place.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Features
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(Icons.attach_money, 'Track income & expenses'),
                  _buildFeatureItem(Icons.speed, 'Create budgets'),
                  _buildFeatureItem(Icons.flag, 'Set financial goals'),
                  _buildFeatureItem(Icons.family_restroom, 'Family collaboration'),
                  _buildFeatureItem(Icons.analytics, 'Reports & analytics'),
                  _buildFeatureItem(Icons.cloud, 'Cloud backup'),
                  _buildFeatureItem(Icons.security, 'Secure authentication'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Links',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pushNamed(context, '/privacy_policy');
                    },
                  ),
                  _buildLinkTile(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    onTap: () {
                      // TODO: Navigate to terms
                      CustomSnackBar.show(
                        context,
                        'Terms of Service coming soon',
                      );
                    },
                  ),
                  _buildLinkTile(
                    icon: Icons.star,
                    title: 'Rate Us',
                    onTap: () {
                      // TODO: Open Play Store
                      CustomSnackBar.show(
                        context,
                        'Rate us on Play Store',
                      );
                    },
                  ),
                  _buildLinkTile(
                    icon: Icons.share,
                    title: 'Share App',
                    onTap: () {
                      // TODO: Share app
                      CustomSnackBar.show(
                        context,
                        'Share app coming soon',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Support
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkTile(
                    icon: Icons.email,
                    title: 'Contact Support',
                    onTap: _contactSupport,
                  ),
                  _buildLinkTile(
                    icon: Icons.help,
                    title: 'FAQ',
                    onTap: () {
                      // TODO: Navigate to FAQ
                      CustomSnackBar.show(
                        context,
                        'FAQ coming soon',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Made with ❤️ by FinFam Team',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© $_buildYear FinFam. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: Colors.grey[600],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      dense: true,
    );
  }
}
