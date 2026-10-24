import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/activity.dart';
import '../database/app_database.dart';

class ActivityRepository {
  ActivityRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

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

  Stream<List<Activity>> watchForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
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
    return _db.transaction(() async {
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
    await (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(
      ActivitiesCompanion(
        title: Value(trimmed),
        startAt: Value(startAt),
        endAt: clearEndAt ? const Value(null) : Value(endAt),
        updatedAt: Value(now),
      ),
    );

    final row = await (_db.select(_db.activities)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _map(row);
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
