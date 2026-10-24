import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/riming_atmosphere.dart';
import '../../home/widgets/activity_timeline.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(historyDaysProvider);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final scheme = Theme.of(context).colorScheme;

    return GlassScaffold(
      background: const RimingAtmosphere(),
      backgroundColor: scheme.surface,
      extendBody: false,
      edgeFade: false,
      contentAwareBrightness: false,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        title: Text(
          '往日记录',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(CupertinoIcons.back, color: scheme.onSurface),
        ),
      ),
      // GlassScaffold does not provide Material; chips/ink need an ancestor.
      body: Material(
        type: MaterialType.transparency,
        child: daysAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (days) {
            if (days.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 48,
                        color: scheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '还没有历史记录',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '从今天开始记第一天吧',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final selected = _selected ?? days.first;
            final activitiesAsync =
                ref.watch(activitiesForDayProvider(selected));
            final dateFmt = DateFormat('yyyy年M月d日 EEEE', 'zh_CN');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: days.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final selectedDay = selected.year == day.year &&
                          selected.month == day.month &&
                          selected.day == day.day;
                      final isToday = day == todayDay;
                      final chipLabel = isToday
                          ? '今天'
                          : DateFormat('M/d', 'zh_CN').format(day);
                      return FilterChip(
                        selected: selectedDay,
                        label: Text(chipLabel),
                        onSelected: (_) => setState(() => _selected = day),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    dateFmt.format(selected),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: activitiesAsync.when(
                    data: (items) => ActivityTimeline(activities: items),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('加载失败：$e')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
