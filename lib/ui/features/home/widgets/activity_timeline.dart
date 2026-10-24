import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/activity.dart';
import '../../../../providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/riming_surface_card.dart';
import 'duration_label.dart';
import 'edit_activity_sheet.dart';

class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({super.key, required this.activities});

  final List<Activity> activities;

  Future<void> _editActivity(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final result = await showEditActivitySheet(context, activity: activity);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(activityRepositoryProvider).updateActivity(
            id: activity.id,
            title: result.title,
            startAt: result.startAt,
            endAt: result.endAt,
            clearEndAt: result.clearEndAt,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activities.isEmpty) {
      return const _EmptyTimeline();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[activities.length - 1 - index];
        final isLast = index == activities.length - 1;
        return _TimelineTile(
          activity: activity,
          isLast: isLast,
          onEdit: () => _editActivity(context, ref, activity),
        );
      },
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondaryContainer.withValues(alpha: 0.7),
              ),
              child: Icon(
                CupertinoIcons.sparkles,
                size: 28,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '今天的空白页',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '点一下中间的大按钮，留下第一段足迹',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.activity,
    required this.isLast,
    required this.onEdit,
  });

  final Activity activity;
  final bool isLast;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ongoing = activity.isOngoing;

    return Semantics(
      button: true,
      label:
          '${activity.title}，从 ${formatClock(activity.startAt)} 开始${ongoing ? '，进行中' : ''}，点击可编辑',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  SizedBox(
                    height: 22,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        formatClock(activity.startAt),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: isLast
                            ? Colors.transparent
                            : scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ongoing ? scheme.primary : scheme.outlineVariant,
                  border: Border.all(
                    color: scheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: RimingSurfaceCard(
                  emphasized: ongoing,
                  onTap: onEdit,
                  onLongPress: onEdit,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            LiveDurationLabel(
                              startAt: activity.startAt,
                              endAt: activity.endAt,
                            ),
                            if (!ongoing && activity.endAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${formatClock(activity.startAt)} – ${formatClock(activity.endAt!)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.outline),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.pencil,
                        size: 18,
                        color: scheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
