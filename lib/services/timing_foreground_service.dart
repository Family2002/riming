import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/time_format.dart';
import '../domain/models/activity.dart';

const _batteryHintShownKey = 'riming_battery_hint_shown';

/// Top-level entry for the foreground task isolate.
@pragma('vm:entry-point')
void timingTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(TimingTaskHandler());
}

class TimingTaskHandler extends TaskHandler {
  String _title = '日铭计时';
  int _startAtMs = 0;

  Future<void> _loadState() async {
    final title = await FlutterForegroundTask.getData(key: 'title');
    final startAtMs = await FlutterForegroundTask.getData(key: 'startAtMs');
    if (title is String && title.isNotEmpty) {
      _title = title;
    }
    if (startAtMs is int) {
      _startAtMs = startAtMs;
    }
  }

  void _refreshNotification() {
    if (_startAtMs <= 0) return;
    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(_startAtMs),
    );
    FlutterForegroundTask.updateService(
      notificationTitle: _title,
      notificationText: '已进行 ${formatDuration(elapsed)} · 点按返回日铭',
    );
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _loadState();
    _refreshNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _refreshNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final title = data['title'];
      final startAtMs = data['startAtMs'];
      if (title is String && title.isNotEmpty) {
        _title = title;
      }
      if (startAtMs is int) {
        _startAtMs = startAtMs;
      }
      _refreshNotification();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}

/// Starts / updates / stops the Android foreground service for ongoing timing.
class TimingForegroundService {
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'riming_timing',
        channelName: '日铭计时',
        channelDescription: '进行中事项的计时通知，用于保持后台稳定运行。',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// Request notification permission; optionally show Xiaomi battery tip once.
  static Future<void> ensurePermissions(
    BuildContext? context, {
    SharedPreferences? prefs,
  }) async {
    if (!Platform.isAndroid) return;

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (context == null || !context.mounted) return;
    final navigatorContext = context;
    final p = prefs ?? await SharedPreferences.getInstance();
    if (p.getBool(_batteryHintShownKey) == true) return;
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await p.setBool(_batteryHintShownKey, true);
      return;
    }
    if (!navigatorContext.mounted) return;

    final go = await showDialog<bool>(
      context: navigatorContext,
      builder: (ctx) => AlertDialog(
        title: const Text('保持后台计时更稳？'),
        content: const Text(
          '小米等机型可能会在后台清理应用，导致通知中断。'
          '建议关闭「日铭」的电池优化（可选，不影响已记录的时间，时长仍按开始时间计算）。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('以后再说'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
    await p.setBool(_batteryHintShownKey, true);
    if (go == true) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  static Future<void> sync(Activity? ongoing) async {
    if (!Platform.isAndroid) return;
    init();

    if (ongoing == null || !ongoing.isOngoing) {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      return;
    }

    await FlutterForegroundTask.saveData(key: 'title', value: ongoing.title);
    await FlutterForegroundTask.saveData(
      key: 'startAtMs',
      value: ongoing.startAt.millisecondsSinceEpoch,
    );

    final elapsed = DateTime.now().difference(ongoing.startAt);
    final text = '已进行 ${formatDuration(elapsed)} · 点按返回日铭';

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: ongoing.title,
        notificationText: text,
      );
      FlutterForegroundTask.sendDataToTask({
        'title': ongoing.title,
        'startAtMs': ongoing.startAt.millisecondsSinceEpoch,
      });
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 2601,
        serviceTypes: const [ForegroundServiceTypes.specialUse],
        notificationTitle: ongoing.title,
        notificationText: text,
        notificationInitialRoute: '/',
        callback: timingTaskStartCallback,
      );
    }
  }
}
