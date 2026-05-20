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
      expect(state.history.first, 5000); // Einträge 0–4 wurden entfernt
      expect(state.history.last, 54000);
    });
  });
}
