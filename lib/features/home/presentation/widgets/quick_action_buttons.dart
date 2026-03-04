import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            context,
            AppLocalizations.of(context)!.notes,
            Icons.note_alt_rounded,
            () => context.push('/notes'),
          ),
          _buildActionButton(
            context,
            AppLocalizations.of(context)!.tasks,
            Icons.check_circle_rounded,
            () => context.push('/tasks'),
          ),
          _buildActionButton(
            context,
            AppLocalizations.of(context)!.calendar,
            Icons.calendar_month_rounded,
            () => context.push('/calendar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHighest : cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(
                    alpha: isDark ? 0.1 : 0.2,
                  ),
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24, color: cs.primary),
                  const Gap(8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
