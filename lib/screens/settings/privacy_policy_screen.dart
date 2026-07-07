// lib/screens/settings/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: $currentYear',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              title: '1. Introduction',
              content: '''
Welcome to FinFam ("we", "our", "us"). We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

Please read this Privacy Policy carefully. By using FinFam, you agree to the collection and use of information in accordance with this policy.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Information we collect
            _buildSection(
              title: '2. Information We Collect',
              content: '''
We collect information that you provide directly to us:

• Account Information: Name, email address, username, phone number
• Financial Data: Income, expenses, budgets, goals, transactions
• Family Data: Family members, relationships, shared budgets
• Device Information: Device type, operating system, app version
• Usage Data: How you interact with the app, features used
• Location Data: Approximate location (if you enable this feature)
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // How we use information
            _buildSection(
              title: '3. How We Use Your Information',
              content: '''
We use your information to:

• Provide and maintain the app's core functionality
• Process and track your financial transactions
• Enable family sharing and collaboration features
• Send you notifications and reminders
• Improve and optimize the app experience
• Provide customer support and respond to inquiries
• Generate analytics and insights to improve our services
• Comply with legal obligations
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Data sharing
            _buildSection(
              title: '4. Data Sharing',
              content: '''
We do not sell your personal information. We may share your information in the following cases:

• With your explicit consent
• With family members you invite to share data
• With service providers who assist in app operations
• When required by law or legal process
• To protect our rights, property, or safety

We ensure that any third parties we share data with maintain appropriate security measures.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Data security
            _buildSection(
              title: '5. Data Security',
              content: '''
We implement robust security measures to protect your data:

• End-to-end encryption for sensitive financial data
• Secure Firebase infrastructure
• Regular security audits and updates
• Strong authentication mechanisms
• Access controls and permissions

While we take every precaution, no method of data transmission or storage is 100% secure.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // User rights
            _buildSection(
              title: '6. Your Rights',
              content: '''
You have the right to:

• Access and view your personal data
• Correct or update your information
• Delete your account and associated data
• Withdraw consent for data processing
• Export your data in a portable format
• Object to certain data processing activities

Contact us to exercise these rights at support@finfam.com
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Data retention
            _buildSection(
              title: '7. Data Retention',
              content: '''
We retain your personal information for as long as your account is active. You can delete your account and all associated data at any time. Some data may be retained longer if required by law or for legitimate business purposes (such as tax reporting).
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Children's privacy
            _buildSection(
              title: '8. Children\'s Privacy',
              content: '''
FinFam is not intended for children under the age of 13. We do not knowingly collect personal information from children. If we discover that we have collected data from a child without parental consent, we will delete it immediately.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Updates to policy
            _buildSection(
              title: '9. Updates to Policy',
              content: '''
We may update this Privacy Policy from time to time. We will notify you of any significant changes by:
• Posting the updated policy in the app
• Sending you a notification
• Displaying a notice when you open the app

We encourage you to review this policy periodically.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Contact
            _buildSection(
              title: '10. Contact Us',
              content: '''
If you have questions, concerns, or requests regarding this Privacy Policy:

📧 Email: support@finfam.com
🌐 Website: finfam.com
📍 Address: FinFam Technologies, 123 Finance Street, Tech City

We will respond to your inquiries within 3 business days.
''',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Acknowledgment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Privacy Matters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We are committed to protecting your privacy and handling your data responsibly. If you have any questions, please contact us.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
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

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
