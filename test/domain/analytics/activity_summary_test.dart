import 'package:flutter_test/flutter_test.dart';
import 'package:riming/domain/analytics/activity_summary.dart';
import 'package:riming/domain/models/activity.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);

  Activity act({
    required String id,
    required String title,
    required DateTime start,
    DateTime? end,
  }) {
    return Activity(
      id: id,
      title: title,
      startAt: start,
      endAt: end,
      updatedAt: start,
    );
  }

  test('sums totals and ranks Top3', () {
    final summary = summarizeActivities(
      [
        act(
          id: '1',
          title: '阅读',
          start: DateTime(2026, 10, 24, 9),
          end: DateTime(2026, 10, 24, 10),
        ),
        act(
          id: '2',
          title: '写作',
          start: DateTime(2026, 10, 24, 10),
          end: DateTime(2026, 10, 24, 12),
        ),
        act(
          id: '3',
          title: '阅读',
          start: DateTime(2026, 10, 24, 14),
          end: DateTime(2026, 10, 24, 14, 30),
        ),
        act(
          id: '4',
          title: '散步',
          start: DateTime(2026, 10, 24, 15),
          end: DateTime(2026, 10, 24, 15, 20),
        ),
      ],
      now: now,
    );

    expect(summary.total, const Duration(hours: 3, minutes: 50));
    expect(summary.top.map((e) => e.title).toList(), ['写作', '阅读', '散步']);
    expect(summary.top[0].duration, const Duration(hours: 2));
    expect(summary.top[1].duration, const Duration(hours: 1, minutes: 30));
  });

  test('uses now for ongoing activity', () {
    final summary = summarizeActivities(
      [
        act(
          id: '1',
          title: '专注',
          start: DateTime(2026, 10, 24, 11),
        ),
      ],
      now: now,
    );
    expect(summary.total, const Duration(hours: 1));
    expect(summary.top.single.title, '专注');
  });
}
