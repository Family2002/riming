String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) {
    return '$hours小时${minutes.toString().padLeft(2, '0')}分';
  }
  if (minutes > 0) {
    return '$minutes分${seconds.toString().padLeft(2, '0')}秒';
  }
  return '$seconds秒';
}

String formatClock(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
