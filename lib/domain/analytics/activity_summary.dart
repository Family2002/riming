import '../models/activity.dart';

/// Aggregated title + duration for light summaries (history / analytics).
class TitleDuration {
  const TitleDuration({required this.title, required this.duration});

  final String title;
  final Duration duration;
}

class ActivitySummary {
  const ActivitySummary({
    required this.total,
    required this.top,
  });

  final Duration total;
  final List<TitleDuration> top;

  bool get isEmpty => total == Duration.zero && top.isEmpty;
}

/// Sum durations and return Top [limit] titles (by duration desc).
///
/// Duration uses [Activity.duration] (`endAt ?? now - startAt`).
ActivitySummary summarizeActivities(
  Iterable<Activity> activities, {
  int limit = 3,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final byTitle = <String, Duration>{};
  var total = Duration.zero;

  for (final a in activities) {
    if (a.deletedAt != null) continue;
    final end = a.endAt ?? clock;
    final d = end.difference(a.startAt);
    if (d.isNegative) continue;
    total += d;
    byTitle[a.title] = (byTitle[a.title] ?? Duration.zero) + d;
  }

  final top = byTitle.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return ActivitySummary(
    total: total,
    top: top
        .take(limit)
        .map((e) => TitleDuration(title: e.key, duration: e.value))
        .toList(),
  );
}
