/// `h:mm:ss`, or `mm:ss` under an hour. Used everywhere a countdown or a
/// step's configured timer length is shown.
String formatDuration(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final h = total.inHours;
  final m = total.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
