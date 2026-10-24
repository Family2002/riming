import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../providers.dart';
import '../../../../services/timing_foreground_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_preferences.dart';
import '../../../core/widgets/riming_atmosphere.dart';
import '../../../core/widgets/riming_surface_card.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/duration_label.dart';
import '../widgets/primary_record_button.dart';
import '../widgets/title_input_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapTiming());
  }

  Future<void> _bootstrapTiming() async {
    if (!mounted) return;
    await TimingForegroundService.ensurePermissions(
      context,
      prefs: ref.read(sharedPreferencesProvider),
    );
    if (!mounted) return;
    final ongoing = await ref.read(activityRepositoryProvider).getOngoing();
    await TimingForegroundService.sync(ongoing);
  }

  Future<void> _onPrimaryTap() async {
    final ongoing = ref.read(ongoingActivityProvider).valueOrNull;
    final title = await showTitleInputSheet(
      context,
      headline: ongoing == null ? '现在要做什么？' : '下一件事是？',
      confirmLabel: ongoing == null ? '开始' : '切换',
    );
    if (title == null || !mounted) return;

    try {
      await ref.read(activityRepositoryProvider).startOrSwitch(title);
      if (ongoing == null && mounted) {
        await TimingForegroundService.ensurePermissions(
          context,
          prefs: ref.read(sharedPreferencesProvider),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法保存：$e')),
      );
    }
  }

  Future<void> _endDay() async {
    final ongoing = ref.read(ongoingActivityProvider).valueOrNull;
    if (ongoing == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束当前事项？'),
        content: Text('将结束「${ongoing.title}」，不会开始新的事项。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('结束'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(activityRepositoryProvider).endCurrent();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(timingForegroundSyncProvider);

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final activitiesAsync = ref.watch(activitiesForDayProvider(day));
    final ongoingAsync = ref.watch(ongoingActivityProvider);
    final hasOngoing = ongoingAsync.valueOrNull != null;
    final dateLabel = DateFormat('M月d日 EEEE', 'zh_CN').format(today);
    final scheme = Theme.of(context).colorScheme;

    return GlassScaffold(
      background: const RimingAtmosphere(),
      backgroundColor: scheme.surface,
      extendBody: false,
      edgeFade: false,
      contentAwareBrightness: false,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        // Match date row inset (AppSpacing.lg); default bar pad is 8.
        padding: const EdgeInsets.only(left: AppSpacing.lg, right: 8),
        title: Text(
          '日铭',
          style: GoogleFonts.maShanZheng(
            textStyle: Theme.of(context).textTheme.headlineSmall,
            color: scheme.onSurface,
            height: 1.1,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '账号与同步',
            onPressed: () => context.push('/account'),
            icon: Icon(CupertinoIcons.person_crop_circle,
                color: scheme.onSurface),
          ),
          IconButton(
            tooltip: '主题',
            onPressed: () => context.push('/themes'),
            icon: Icon(CupertinoIcons.paintbrush, color: scheme.onSurface),
          ),
          IconButton(
            tooltip: '往日记录',
            onPressed: () => context.push('/history'),
            icon: Icon(CupertinoIcons.calendar, color: scheme.onSurface),
          ),
        ],
      ),
      // Hero CTA in Expanded/Center for airy vertical space; timeline keeps
      // its own Expanded so it is not crushed.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: hasOngoing
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: _OngoingBanner(
                            title: ongoingAsync.valueOrNull!.title,
                            startAt: ongoingAsync.valueOrNull!.startAt,
                            onEnd: _endDay,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: PrimaryRecordButton(
                hasOngoing: hasOngoing,
                onPressed: _onPrimaryTap,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  '今日时间线',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (activitiesAsync.hasValue &&
                    activitiesAsync.value!.isNotEmpty)
                  Text(
                    '${activitiesAsync.value!.length} 段',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: activitiesAsync.when(
              data: (items) => ActivityTimeline(activities: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _OngoingBanner extends StatelessWidget {
  const _OngoingBanner({
    required this.title,
    required this.startAt,
    required this.onEnd,
  });

  final String title;
  final DateTime startAt;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RimingSurfaceCard(
      emphasized: true,
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正在 · $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                LiveDurationLabel(
                  startAt: startAt,
                  endAt: null,
                  prefix: '已进行 ',
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEnd,
            child: Text(
              '结束',
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
