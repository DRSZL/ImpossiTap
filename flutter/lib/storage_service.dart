import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';

class StorageService {
  static const _keyBestDeviation = 'best_deviation';
  static const _keyTriesToday = 'tries_today';
  static const _keyHistoryToday = 'history_today';
  static const _keyLastPlayedDate = 'last_played_date';
  static const _keyStreak = 'streak';

  String _dateStr(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String get _today => _dateStr(DateTime.now());
  String get _yesterday =>
      _dateStr(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> load(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    state.streak = prefs.getInt(_keyStreak) ?? 0;

    final lastPlayed = prefs.getString(_keyLastPlayedDate);
    if (lastPlayed != _today) return;

    if (prefs.containsKey(_keyBestDeviation)) {
      state.bestDeviation = prefs.getInt(_keyBestDeviation);
    }
    state.tries = prefs.getInt(_keyTriesToday) ?? 0;
    final rawHistory = prefs.getString(_keyHistoryToday);
    if (rawHistory != null) {
      state.history = List<int>.from(jsonDecode(rawHistory) as List);
    }
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString(_keyLastPlayedDate);
    final today = _today;

    if (lastPlayed == null) {
      state.streak = 1;
    } else if (lastPlayed != today) {
      state.streak = (lastPlayed == _yesterday) ? state.streak + 1 : 1;
    }

    if (state.bestDeviation != null) {
      await prefs.setInt(_keyBestDeviation, state.bestDeviation!);
    } else {
      await prefs.remove(_keyBestDeviation);
    }
    await prefs.setInt(_keyTriesToday, state.tries);
    await prefs.setString(_keyHistoryToday, jsonEncode(state.history));
    await prefs.setString(_keyLastPlayedDate, today);
    await prefs.setInt(_keyStreak, state.streak);
  }
}
