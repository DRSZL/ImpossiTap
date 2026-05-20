class GameState {
  static const int _targetMin = 700000;
  static const int _targetMax = 2000000;
  static const int _lcgMultiplier = 1664525;
  static const int _lcgIncrement = 1013904223;

  static int get targetUs => targetForDate(DateTime.now());

  static int targetForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final hash = (seed * _lcgMultiplier + _lcgIncrement) & 0x7FFFFFFF;
    return _targetMin + (hash % (_targetMax - _targetMin));
  }

  int tries = 0;
  int? bestDeviation;
  List<int> history = [];
  int streak = 0;

  int get bestUs => targetUs + (bestDeviation ?? 0);

  void recordAttempt(int deviationNs) {
    tries++;
    if (bestDeviation == null || deviationNs.abs() < bestDeviation!.abs()) {
      bestDeviation = deviationNs;
    }
    history.add(deviationNs);
    if (history.length > 50) history.removeAt(0);
  }

  String get formattedBest {
    if (bestDeviation == null) return '—';
    return formatUs(bestUs);
  }

  static String formatUs(int us) => _formatUs(us);

  static String _formatUs(int us) {
    final str = us.toString();
    final buffer = StringBuffer();
    final offset = str.length % 3;
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (i - offset) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String gradeLabel(int devUs) {
    final absMs = devUs.abs() / 1000;
    if (absMs <= 20) return 'UNMÖGLICH';
    if (absMs <= 80) return 'STARK';
    if (absMs <= 200) return 'SOLIDE';
    return 'ÜBEN';
  }

  String gradeEmoji(int devUs) {
    final absMs = devUs.abs() / 1000;
    if (absMs <= 20) return '🏆';
    if (absMs <= 80) return '🔥';
    if (absMs <= 200) return '👍';
    return '😬';
  }

  int rankPercent(int devUs) {
    final absMs = devUs.abs() / 1000;
    return (99 - absMs / 5).round().clamp(10, 99);
  }
}
