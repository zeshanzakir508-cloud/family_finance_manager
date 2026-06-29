import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for FinFam',
              style: AppTheme.headingStyle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: June 2024',
              style: AppTheme.captionStyle,
            ),
            const SizedBox(height: 24),

            _buildSection(
              '1. Information We Collect',
              [
                '• Email address (for login and account management)',
                '• Full name (for profile display)',
                '• Phone number (for family contact)',
                '• Transaction data (income, expenses, categories)',
                '• Family data (family members, relationships)',
                '• Profile images (if uploaded)',
                '• Device information (for app optimization)',
              ],
            ),

            _buildSection(
              '2. How We Use Your Information',
              [
                '• To provide and maintain the app',
                '• To enable family sharing features',
                '• To sync data across your devices',
                '• To generate reports and analytics',
                '• To improve user experience',
                '• To send notifications (if enabled)',
              ],
            ),

            _buildSection(
              '3. Data Sharing',
              [
                '• Data is shared only within your family circle',
                '• We do NOT sell your data to third parties',
                '• We do NOT share data with advertisers',
                '• Data is stored securely on Firebase servers',
              ],
            ),

            _buildSection(
              '4. Data Security',
              [
                '• All data is encrypted during transmission',
                '• Firebase security rules protect your data',
                '• You control who is in your family circle',
                '• Your password is securely stored',
              ],
            ),

            _buildSection(
              '5. Your Rights',
              [
                '• Access: View all your data',
                '• Correction: Update your profile',
                '• Deletion: Delete your account anytime',
                '• Export: Download your data',
                '• Withdraw consent: Stop using the app',
              ],
            ),

            _buildSection(
              '6. Contact Us',
              [
                'Email: finfam@support.com',
                'If you have any questions about this Privacy Policy.',
              ],
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'By using FinFam, you agree to this Privacy Policy.',
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
