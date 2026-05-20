import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:impossitap/game_state.dart';
import 'package:impossitap/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService.load', () {
    test('empty storage leaves state at defaults', () async {
      final state = GameState();
      await StorageService().load(state);
      expect(state.tries, 0);
      expect(state.bestDeviation, null);
      expect(state.history, isEmpty);
      expect(state.streak, 0);
    });

    test('loads todays data when last_played_date is today', () async {
      final today = _dateStr(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'last_played_date': today,
        'tries_today': 3,
        'best_deviation': 12000,
        'history_today': '[10000,-5000,12000]',
        'streak': 4,
      });
      final state = GameState();
      await StorageService().load(state);
      expect(state.tries, 3);
      expect(state.bestDeviation, 12000);
      expect(state.history, [10000, -5000, 12000]);
      expect(state.streak, 4);
    });

    test('ignores daily stats when last_played_date is not today', () async {
      SharedPreferences.setMockInitialValues({
        'last_played_date': '2000-01-01',
        'tries_today': 99,
        'best_deviation': 1,
        'history_today': '[1]',
        'streak': 7,
      });
      final state = GameState();
      await StorageService().load(state);
      expect(state.tries, 0);
      expect(state.bestDeviation, null);
      expect(state.history, isEmpty);
      expect(state.streak, 7); // Streak wird immer geladen
    });
  });

  group('StorageService.save', () {
    test('first ever save sets streak to 1', () async {
      final state = GameState()..recordAttempt(5000);
      await StorageService().save(state);
      expect(state.streak, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('streak'), 1);
    });

    test('save on consecutive day increments streak', () async {
      final yesterday =
          _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'last_played_date': yesterday,
        'streak': 3,
      });
      final state = GameState()
        ..streak = 3
        ..recordAttempt(5000);
      await StorageService().save(state);
      expect(state.streak, 4);
    });

    test('save after gap resets streak to 1', () async {
      SharedPreferences.setMockInitialValues({
        'last_played_date': '2000-01-01',
        'streak': 10,
      });
      final state = GameState()
        ..streak = 10
        ..recordAttempt(5000);
      await StorageService().save(state);
      expect(state.streak, 1);
    });

    test('second save same day keeps streak unchanged', () async {
      final today = _dateStr(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'last_played_date': today,
        'streak': 5,
      });
      final state = GameState()
        ..streak = 5
        ..recordAttempt(5000);
      await StorageService().save(state);
      expect(state.streak, 5);
    });

    test('save then load round-trips all fields', () async {
      final yesterday =
          _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'last_played_date': yesterday,
        'streak': 2,
      });
      final original = GameState()
        ..streak = 2
        ..recordAttempt(8000)
        ..recordAttempt(-3000);
      await StorageService().save(original);
      expect(original.streak, 3); // yesterday → increment

      final loaded = GameState();
      await StorageService().load(loaded);
      expect(loaded.tries, 2);
      expect(loaded.bestDeviation, -3000);
      expect(loaded.history, [8000, -3000]);
      expect(loaded.streak, 3);
    });
  });
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
