class GameState {
  static const int targetUs = 1337000; // 1.337 seconds in microseconds

  int tries = 0;
  int? bestDeviation; // in nanoseconds, can be negative

  int get bestUs => targetUs + (bestDeviation ?? 0);

  void recordAttempt(int deviationNs) {
    tries++;
    if (bestDeviation == null || deviationNs.abs() < bestDeviation!.abs()) {
      bestDeviation = deviationNs;
    }
  }

  String get formattedBest {
    if (bestDeviation == null) return '—';
    return formatUs(bestUs);
  }

  static String formatUs(int us) => _formatUs(us);

  static String _formatUs(int us) {
    // Format with German thousands separator
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
