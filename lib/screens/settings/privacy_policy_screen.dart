// lib/screens/settings/privacy_policy_screen.dart
import 'package:flutter/material.dart';
// ✅ REMOVED: url_launcher (not needed)
import '../../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last updated: July 2024',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              title: '1. Introduction',
              content: 'FinFam ("we", "our", "us") is committed to protecting your privacy. '
                  'This Privacy Policy explains how we collect, use, and safeguard your personal information '
                  'when you use our family finance management application.',
            ),
            const SizedBox(height: 16),

            // Information We Collect
            _buildSection(
              title: '2. Information We Collect',
              content: 'We collect information you provide directly:',
              bulletPoints: [
                'Name and email address',
                'Financial transaction data you enter',
                'Family member information',
                'Budget and expense categories',
                'Profile photo (if uploaded)',
                'Device information for app functionality',
              ],
            ),
            const SizedBox(height: 16),

            // How We Use Information
            _buildSection(
              title: '3. How We Use Your Information',
              content: 'We use your information to:',
              bulletPoints: [
                'Provide and maintain the app services',
                'Track and manage your financial data',
                'Generate reports and analytics',
                'Send transaction notifications',
                'Improve app functionality',
                'Provide customer support',
              ],
            ),
            const SizedBox(height: 16),

            // Data Storage
            _buildSection(
              title: '4. Data Storage and Security',
              content: 'Your data is stored securely:',
              bulletPoints: [
                'All data is encrypted in transit and at rest',
                'Firebase Firestore for secure cloud storage',
                'Local storage for offline access',
                'We never sell or share your data with third parties',
                'You can delete your data anytime',
              ],
            ),
            const SizedBox(height: 16),

            // Your Rights
            _buildSection(
              title: '5. Your Rights',
              content: 'You have the right to:',
              bulletPoints: [
                'Access your personal data',
                'Correct inaccurate data',
                'Delete your account and data',
                'Export your data (CSV format)',
                'Opt-out of notifications',
                'Request data portability',
              ],
            ),
            const SizedBox(height: 16),

            // Children's Privacy
            _buildSection(
              title: '6. Children\'s Privacy',
              content: 'FinFam is not intended for children under 13. '
                  'We do not knowingly collect personal information from children under 13. '
                  'If you are a parent and believe your child has provided us with personal information, '
                  'please contact us.',
            ),
            const SizedBox(height: 16),

            // Changes to Policy
            _buildSection(
              title: '7. Changes to This Policy',
              content: 'We may update this Privacy Policy from time to time. '
                  'We will notify you of any changes by posting the new policy in the app. '
                  'You are advised to review this policy periodically for any changes.',
            ),
            const SizedBox(height: 16),

            // Contact Us - Email only (FIXED for #18, #37)
            _buildSection(
              title: '8. Contact Us',
              content: 'If you have questions about this Privacy Policy, please contact us at:',
              bulletPoints: [
                '📧 Email: zeshanzakir508@gmail.com',
                '📱 App: FinFam - Family Finance Manager',
              ],
            ),
            const SizedBox(height: 24),

            // Consent/Agreement
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'By using FinFam, you agree to our Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We respect your privacy and protect your data',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    List<String>? bulletPoints,
  }) {
    return Column(
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
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
        if (bulletPoints != null) ...[
          const SizedBox(height: 8),
          ...bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ],
    );
  }
}
