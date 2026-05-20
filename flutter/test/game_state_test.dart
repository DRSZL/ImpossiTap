import 'package:flutter_test/flutter_test.dart';
import 'package:impossitap/game_state.dart';

void main() {
  group('GameState', () {
    test('history starts empty', () {
      expect(GameState().history, isEmpty);
    });

    test('streak starts at 0', () {
      expect(GameState().streak, 0);
    });

    test('recordAttempt adds deviation to history', () {
      final state = GameState();
      state.recordAttempt(5000);
      expect(state.history, [5000]);
    });

    test('recordAttempt keeps last 50 entries', () {
      final state = GameState();
      for (int i = 0; i < 55; i++) {
        state.recordAttempt(i * 1000);
      }
      expect(state.history.length, 50);
      expect(state.history.first, 5000);
      expect(state.history.last, 54000);
    });
  });

  group('GameState.targetForDate', () {
    test('returns same value for same date', () {
      final date = DateTime(2026, 5, 20);
      expect(GameState.targetForDate(date), GameState.targetForDate(date));
    });

    test('returns different values for different dates', () {
      final d1 = DateTime(2026, 5, 20);
      final d2 = DateTime(2026, 5, 21);
      expect(GameState.targetForDate(d1), isNot(GameState.targetForDate(d2)));
    });

    test('is within valid range', () {
      final target = GameState.targetForDate(DateTime(2026, 5, 20));
      expect(target, greaterThanOrEqualTo(700000));
      expect(target, lessThan(2000000));
    });
  });
}
