import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/generated/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'daitr2024@gmail.com',
      queryParameters: {'subject': 'Personality.ai - Feedback'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutApp),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App Logo & Title
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: theme.primaryColor,
                  ),
                ),
                const Gap(16),
                Text(
                  'Personality.ai',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Gap(4),
                Text(
                  '${l10n.version} 1.0.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Gap(32),

          // App Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primaryColor),
                    const Gap(8),
                    Text(
                      l10n.aboutAppTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Text(
                  _getAppDescription(l10n),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Features
          _buildFeatureItem(
            icon: Icons.task_alt,
            title: l10n.tasks,
            color: Colors.green,
          ),
          _buildFeatureItem(
            icon: Icons.note_alt_outlined,
            title: l10n.notes,
            color: Colors.purple,
          ),
          _buildFeatureItem(
            icon: Icons.calendar_month,
            title: l10n.calendar,
            color: Colors.blue,
          ),
          _buildFeatureItem(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.financeTitle,
            color: Colors.orange,
          ),
          _buildFeatureItem(
            icon: Icons.auto_awesome,
            title: l10n.aiConfiguration,
            color: Colors.deepPurple,
          ),

          const Gap(24),

          // ── Contact / Support Section ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.08),
                  theme.primaryColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        color: theme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.contactUs,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            l10n.feedbackAndSupport,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                Text(
                  l10n.contactUsSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const Gap(16),
                // Email address chip
                InkWell(
                  onTap: _launchEmail,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email_rounded,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            'daitr2024@gmail.com',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(12),
                // Send email button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launchEmail,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(l10n.sendEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Privacy Policy Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                    const Gap(8),
                    Text(
                      l10n.privacyPolicy,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Text(
                  l10n.privacyPolicyContent,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const Gap(32),

          // Footer
          Center(
            child: Text(
              '© 2026 Personality.ai',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          // Extra bottom padding to prevent content from being hidden
          // behind the system navigation bar
          const Gap(48),
        ],
      ),
    );
  }

  String _getAppDescription(AppLocalizations l10n) {
    // Use locale-specific description
    switch (l10n.localeName) {
      case 'en':
        return 'Personality.ai is your intelligent personal assistant. '
            'Manage your tasks, notes, calendar events, and finances — '
            'all enhanced with AI capabilities for smarter productivity.';
      case 'ar':
        return 'Personality.ai هو مساعدك الشخصي الذكي. '
            'إدارة مهامك وملاحظاتك وأحداث التقويم والشؤون المالية — '
            'كل ذلك معزز بقدرات الذكاء الاصطناعي لإنتاجية أذكى.';
      default:
        return 'Personality.ai, akıllı kişisel asistanınızdır. '
            'Görevlerinizi, notlarınızı, takvim etkinliklerinizi ve '
            'finanslarınızı yönetin — hepsi yapay zeka yetenekleriyle '
            'geliştirilmiş daha akıllı üretkenlik için.';
    }
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        dense: true,
      ),
    );
  }
}
