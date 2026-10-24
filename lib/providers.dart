import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/app_database.dart';
import 'data/repositories/activity_repository.dart';
import 'domain/models/activity.dart';
import 'services/timing_foreground_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(databaseProvider));
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final activitiesForDayProvider =
    StreamProvider.family<List<Activity>, DateTime>((ref, day) {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchForDay(day);
});

/// Rolling 7 local calendar days ending on [anchorDay] (inclusive).
final activitiesForWeekEndingProvider =
    StreamProvider.family<List<Activity>, DateTime>((ref, anchorDay) {
  final repo = ref.watch(activityRepositoryProvider);
  final endDay = DateTime(anchorDay.year, anchorDay.month, anchorDay.day);
  final start = endDay.subtract(const Duration(days: 6));
  final endExclusive = endDay.add(const Duration(days: 1));
  return repo.watchForRange(start, endExclusive);
});

final ongoingActivityProvider = StreamProvider<Activity?>((ref) {
  return ref.watch(activityRepositoryProvider).watchOngoing();
});

final historyDaysProvider = FutureProvider<List<DateTime>>((ref) {
  return ref.watch(activityRepositoryProvider).daysWithActivities();
});

/// Keeps Android foreground notification in sync with the ongoing activity.
final timingForegroundSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Activity?>>(ongoingActivityProvider, (previous, next) {
    next.whenData(TimingForegroundService.sync);
  });
});
