import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/statistics_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Statistics page showing productivity metrics with premium design
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStats = ref.watch(todayStatsProvider);
    final totalTasks = ref.watch(totalTasksCompletedProvider);
    final completionRate = ref.watch(completionRateProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Stats Section
            _buildSectionHeader(context, 'Bugün', Icons.today_rounded),
            const Gap(16),
            todayStats.when(
              data: (stats) => _buildTodayStatsCard(context, stats),
              loading: () => _buildLoadingCard(height: 180),
              error: (error, stack) => _buildErrorCard('Veri yüklenemedi'),
            ),
            const Gap(32),

            // Overall Stats Section
            _buildSectionHeader(
              context,
              'Genel Performans',
              Icons.insights_rounded,
            ),
            const Gap(16),
            _buildOverallStatsGrid(
              context,
              totalTasks,
              completionRate,
              currentStreak,
              longestStreak,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const Gap(12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatsCard(BuildContext context, dynamic stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.1 : 0.2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            context,
            'Tamamlanan Görevler',
            stats.tasksCompleted.toString(),
            AppTheme.completedColor,
            Icons.check_circle_rounded,
          ),
          _buildDivider(context),
          _buildStatRow(
            context,
            'Oluşturulan Görevler',
            stats.tasksCreated.toString(),
            AppTheme.taskColor,
            Icons.add_task_rounded,
          ),
          _buildDivider(context),
          _buildStatRow(
            context,
            'Oluşturulan Notlar',
            stats.notesCreated.toString(),
            AppTheme.noteColor,
            Icons.note_alt_rounded,
          ),
          _buildDivider(context),
          _buildStatRow(
            context,
            'Yeni Etkinlikler',
            stats.eventsAttended.toString(),
            AppTheme.eventColor,
            Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 24,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  Widget _buildOverallStatsGrid(
    BuildContext context,
    AsyncValue<int> totalTasks,
    AsyncValue<double> completionRate,
    AsyncValue<int> currentStreak,
    AsyncValue<int> longestStreak,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        totalTasks.when(
          data: (value) => _buildSummaryCard(
            context,
            'Toplam Başarı',
            value.toString(),
            AppTheme.completedColor,
            Icons.emoji_events_rounded,
          ),
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildErrorCard('Hata'),
        ),
        completionRate.when(
          data: (value) => _buildSummaryCard(
            context,
            'Verimlilik Oranı',
            '${value.toStringAsFixed(1)}%',
            AppTheme.eventColor,
            Icons.analytics_rounded,
          ),
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildErrorCard('Hata'),
        ),
        currentStreak.when(
          data: (value) => _buildSummaryCard(
            context,
            'Mevcut Seri',
            '$value Gün',
            AppTheme.taskColor,
            Icons.local_fire_department_rounded,
          ),
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildErrorCard('Hata'),
        ),
        longestStreak.when(
          data: (value) => _buildSummaryCard(
            context,
            'Rekor Seri',
            '$value Gün',
            AppTheme.urgentColor,
            Icons.workspace_premium_rounded,
          ),
          loading: () => _buildLoadingCard(),
          error: (error, stack) => _buildErrorCard('Hata'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.1 : 0.2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 64, color: color.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }
}
