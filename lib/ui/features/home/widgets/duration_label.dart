import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/time_format.dart';

export '../../../../core/time_format.dart';

/// Static duration for finished activities.
class DurationLabel extends StatelessWidget {
  const DurationLabel({super.key, required this.duration, this.ongoing = false});

  final Duration duration;
  final bool ongoing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      ongoing ? '进行中 · ${formatDuration(duration)}' : formatDuration(duration),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ongoing ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: ongoing ? FontWeight.w600 : FontWeight.w400,
          ),
    );
  }
}

/// Ticks every second while [endAt] is null; only this label rebuilds.
class LiveDurationLabel extends StatefulWidget {
  const LiveDurationLabel({
    super.key,
    required this.startAt,
    this.endAt,
    this.prefix = '进行中 · ',
  });

  final DateTime startAt;
  final DateTime? endAt;
  final String prefix;

  @override
  State<LiveDurationLabel> createState() => _LiveDurationLabelState();
}

class _LiveDurationLabelState extends State<LiveDurationLabel> {
  Timer? _timer;

  bool get _ongoing => widget.endAt == null;

  Duration get _duration {
    final end = widget.endAt ?? DateTime.now();
    return end.difference(widget.startAt);
  }

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant LiveDurationLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endAt != widget.endAt ||
        oldWidget.startAt != widget.startAt) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (_ongoing) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = _ongoing
        ? '${widget.prefix}${formatDuration(_duration)}'
        : formatDuration(_duration);
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _ongoing ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: _ongoing ? FontWeight.w600 : FontWeight.w400,
          ),
    );
  }
}
