import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/activity.dart';
import '../database/app_database.dart';

class ActivityRepository {
  ActivityRepository(this._db, {this.onLocalWrite});

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Fired after local mutations so cloud sync can debounce a push.
  void Function()? onLocalWrite;

  void _notifyWrite() => onLocalWrite?.call();

  Activity _map(ActivityRow row) {
    return Activity(
      id: row.id,
      title: row.title,
      startAt: row.startAt,
      endAt: row.endAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  /// All rows including soft-deleted (for sync).
  Future<List<Activity>> getAllIncludingDeleted() async {
    final rows = await _db.select(_db.activities).get();
    return rows.map(_map).toList();
  }

  /// Insert or replace from remote / merge without changing [updatedAt].
  Future<void> upsertFromSync(Activity activity) async {
    await _db.into(_db.activities).insertOnConflictUpdate(
          ActivitiesCompanion(
            id: Value(activity.id),
            title: Value(activity.title),
            startAt: Value(activity.startAt),
            endAt: Value(activity.endAt),
            updatedAt: Value(activity.updatedAt),
            deletedAt: Value(activity.deletedAt),
          ),
        );
  }

  /// Ends extras so at most one non-deleted ongoing activity remains.
  /// Keeps the one with the latest [startAt] (then [updatedAt]).
  /// Does not bump the keeper's [updatedAt] (avoids needless LWW fights).
  Future<void> enforceSingleOngoing() async {
    final ongoing = await (_db.select(_db.activities)
          ..where((t) => t.deletedAt.isNull() & t.endAt.isNull()))
        .get();
    if (ongoing.length <= 1) return;

    ongoing.sort((a, b) {
      final byStart = b.startAt.compareTo(a.startAt);
      if (byStart != 0) return byStart;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    final now = DateTime.now();
    for (final row in ongoing.skip(1)) {
      await (_db.update(_db.activities)..where((t) => t.id.equals(row.id)))
          .write(
        ActivitiesCompanion(
          endAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Hard-clears local activities (account switch — prevent cross-user merge).
  Future<void> clearAllLocal() async {
    await _db.delete(_db.activities).go();
  }

  Stream<List<Activity>> watchForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return watchForRange(start, end);
  }

  /// Inclusive [start], exclusive [end] on local [Activity.startAt].
  Stream<List<Activity>> watchForRange(DateTime start, DateTime end) {
    final query = (_db.select(_db.activities)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.startAt.isBiggerOrEqualValue(start) &
                t.startAt.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
    return query.map((rows) => rows.map(_map).toList());
  }

  Stream<Activity?> watchOngoing() {
    final query = (_db.select(_db.activities)
          ..where((t) => t.deletedAt.isNull() & t.endAt.isNull())
          ..limit(1))
        .watch();
    return query.map((rows) => rows.isEmpty ? null : _map(rows.first));
  }

  Future<Activity?> getOngoing() async {
    final row = await (_db.select(_db.activities)
          ..where((t) => t.deletedAt.isNull() & t.endAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// Ends any ongoing activity, then starts a new one with [title].
  Future<Activity> startOrSwitch(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('事项名称不能为空');
    }

    final now = DateTime.now();
    final created = await _db.transaction(() async {
      final ongoing = await (_db.select(_db.activities)
            ..where((t) => t.deletedAt.isNull() & t.endAt.isNull()))
          .get();
      for (final row in ongoing) {
        await (_db.update(_db.activities)..where((t) => t.id.equals(row.id)))
            .write(
          ActivitiesCompanion(
            endAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      final id = _uuid.v4();
      await _db.into(_db.activities).insert(
            ActivitiesCompanion.insert(
              id: id,
              title: trimmed,
              startAt: now,
              updatedAt: now,
            ),
          );

      return Activity(
        id: id,
        title: trimmed,
        startAt: now,
        updatedAt: now,
      );
    });
    _notifyWrite();
    return created;
  }

  /// Ends the current activity without starting a new one.
  Future<void> endCurrent() async {
    final now = DateTime.now();
    await (_db.update(_db.activities)
          ..where((t) => t.deletedAt.isNull() & t.endAt.isNull()))
        .write(
      ActivitiesCompanion(
        endAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    _notifyWrite();
  }

  /// Updates title and/or times. Clears [endAt] when [clearEndAt] is true
  /// (keep as ongoing). Always bumps [updatedAt].
  Future<Activity> updateActivity({
    required String id,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    bool clearEndAt = false,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('事项名称不能为空');
    }
    if (!clearEndAt && endAt != null && endAt.isBefore(startAt)) {
      throw ArgumentError('结束时间不能早于开始时间');
    }

    final now = DateTime.now();
    // clearEndAt or explicitly null endAt → row becomes the sole ongoing.
    final becomingOngoing = clearEndAt || endAt == null;
    await _db.transaction(() async {
      if (becomingOngoing) {
        final others = await (_db.select(_db.activities)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.endAt.isNull() &
                    t.id.isNotValue(id),
              ))
            .get();
        for (final row in others) {
          await (_db.update(_db.activities)..where((t) => t.id.equals(row.id)))
              .write(
            ActivitiesCompanion(
              endAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      }

      await (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(
        ActivitiesCompanion(
          title: Value(trimmed),
          startAt: Value(startAt),
          endAt: clearEndAt ? const Value(null) : Value(endAt),
          updatedAt: Value(now),
        ),
      );
    });

    final row = await (_db.select(_db.activities)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    _notifyWrite();
    return _map(row);
  }

  /// Non-deleted activities whose [startAt] falls in [[from], [toExclusive]).
  Future<List<Activity>> listForRange(
    DateTime from,
    DateTime toExclusive,
  ) async {
    final rows = await (_db.select(_db.activities)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.startAt.isBiggerOrEqualValue(from) &
                t.startAt.isSmallerThanValue(toExclusive),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
    return rows.map(_map).toList();
  }

  /// Days that have at least one non-deleted activity (newest first).
  Future<List<DateTime>> daysWithActivities({int limit = 90}) async {
    final rows = await (_db.select(_db.activities)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startAt)]))
        .get();

    final seen = <String>{};
    final days = <DateTime>[];
    for (final row in rows) {
      final d = DateTime(row.startAt.year, row.startAt.month, row.startAt.day);
      final key = '${d.year}-${d.month}-${d.day}';
      if (seen.add(key)) {
        days.add(d);
        if (days.length >= limit) break;
      }
    }
    return days;
  }
}
