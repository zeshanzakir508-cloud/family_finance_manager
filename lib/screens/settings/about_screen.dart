import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('About FinFam'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FinFam',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Family Finance Manager',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $_version (Build $_buildNumber)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem('💰 Track income and expenses'),
                  _buildFeatureItem('👨‍👩‍👧‍👦 Family mode with members'),
                  _buildFeatureItem('🌍 100+ currencies with live rates'),
                  _buildFeatureItem('📊 Detailed reports and charts'),
                  _buildFeatureItem('🔒 Secure with PIN and fingerprint'),
                  _buildFeatureItem('📱 Works offline with cached rates'),
                ],
              ),
            ),
            
            const Divider(),
            
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkItem(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'zeshanzakir508@gmail.com',
                    onTap: () => _launchEmail('zeshanzakir508@gmail.com'),
                  ),
                  _buildLinkItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _launchUrl('https://your-privacy-policy-url.com'),
                  ),
                  _buildLinkItem(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    onTap: () => _launchUrl('https://your-terms-url.com'),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Made with ❤️ by Zeshan Zakir',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
