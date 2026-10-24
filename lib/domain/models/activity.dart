/// Domain model for a timed activity segment.
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isOngoing => endAt == null && deletedAt == null;

  Duration get duration {
    final end = endAt ?? DateTime.now();
    return end.difference(startAt);
  }

  Activity copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool clearEndAt = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
