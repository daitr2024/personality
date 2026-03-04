import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/unified_agenda_item.dart';

class TasksArchivePage extends ConsumerWidget {
  const TasksArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.archiveTasks),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          // Filter tasks older than 1 week
          final now = DateTime.now();
          final oneWeekAgo = now.subtract(const Duration(days: 7));

          final archivedTasks = tasks.where((t) {
            if (t.date == null) return false;
            return t.date!.isBefore(oneWeekAgo);
          }).toList();

          // Separate by completion status
          final completedArchived = archivedTasks
              .where((t) => t.isCompleted)
              .toList();
          final uncompletedArchived = archivedTasks
              .where((t) => !t.isCompleted)
              .toList();

          if (archivedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const Gap(16),
                  Text(
                    'Arşivlenmiş görev yok',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            children: [
              // Uncompleted Archived Tasks
              if (uncompletedArchived.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Tamamlanmayan (${uncompletedArchived.length})',
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
                const Gap(12),
                ...uncompletedArchived.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: UnifiedAgendaItem(
                      item: task,
                      showDate: true,
                      onEdit: () => _showTaskEditDialog(
                        context,
                        ref,
                        task.id,
                        task.title,
                        task.date,
                        task.isUrgent,
                      ),
                    ),
                  );
                }),
                const Gap(24),
              ],

              // Completed Archived Tasks
              if (completedArchived.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Tamamlanan (${completedArchived.length})',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                const Gap(12),
                ...completedArchived.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: UnifiedAgendaItem(
                      item: task,
                      showDate: true,
                      onEdit: () => _showTaskEditDialog(
                        context,
                        ref,
                        task.id,
                        task.title,
                        task.date,
                        task.isUrgent,
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('${AppLocalizations.of(context)!.error}: $err')),
      ),
    );
  }

  void _showTaskEditDialog(
    BuildContext context,
    WidgetRef ref,
    int id,
    String currentTitle,
    DateTime? currentDate,
    bool currentUrgent,
  ) {
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(AppLocalizations.of(context)!.editTask),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.taskTitleHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(tasksRepositoryProvider)
                    .updateTaskContent(
                      id,
                      controller.text,
                      currentDate,
                      currentUrgent,
                    );
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
