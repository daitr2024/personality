import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/dashboard_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/unified_agenda_item.dart';

class OverdueTasksDialog extends ConsumerWidget {
  const OverdueTasksDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueAsync = ref.watch(overdueTasksProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade400,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: overdueAsync.when(
                    data: (tasks) => Text(
                      AppLocalizations.of(
                        context,
                      )!.overdueTasksTitle(tasks.length),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => Text(AppLocalizations.of(context)!.loading),
                    error: (e, s) => Text(AppLocalizations.of(context)!.error),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Text(
              AppLocalizations.of(context)!.overdueTasksDesc,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Gap(24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: overdueAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.noOverdueTasks),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return UnifiedAgendaItem(item: task, showDate: true);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Text('${AppLocalizations.of(context)!.error}: $e'),
              ),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
