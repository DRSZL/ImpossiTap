# Datenpersistenz Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Spielerdaten (bestes Ergebnis, Versuchshistorie, Streak) zwischen App-Sessions persistent speichern via SharedPreferences.

**Architecture:** Ein neuer `StorageService` kapselt alle SharedPreferences-Aufrufe. `GameState` bekommt `history` (List<int>, max 50 Einträge) und `streak` (int). `GameScreen` speichert nach jedem Versuch. `HomeScreen` lädt beim Start. `StatsScreen` zeigt echte Chart-Daten und den echten Streak.

**Tech Stack:** Flutter, shared_preferences ^2.2.2 (bereits in pubspec), dart:convert

---

## Dateiübersicht

| Datei | Aktion | Zweck |
|-------|--------|-------|
| `flutter/lib/game_state.dart` | Modify | +history, +streak; recordAttempt erweitert |
| `flutter/lib/storage_service.dart` | **Create** | SharedPreferences load/save kapseln |
| `flutter/lib/screens/game_screen.dart` | Modify | save() nach recordAttempt aufrufen |
| `flutter/lib/screens/home_screen.dart` | Modify | load() in initState aufrufen |
| `flutter/lib/screens/stats_screen.dart` | Modify | Echte Chart-Daten, echter Streak |
| `flutter/test/game_state_test.dart` | **Create** | Unit-Tests GameState |
| `flutter/test/storage_service_test.dart` | **Create** | Unit-Tests StorageService |

---

### Task 1: GameState erweitern

**Files:**
- Modify: `flutter/lib/game_state.dart`
- Create: `flutter/test/game_state_test.dart`

- [ ] **Step 1: Test schreiben**

Erstelle `flutter/test/game_state_test.dart`:
```dart
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
```

- [ ] **Step 2: Test ausführen — erwartet: FAIL**

```bash
cd flutter && flutter test test/game_state_test.dart
```
Erwartet: Kompilierfehler (`history` und `streak` existieren noch nicht).

- [ ] **Step 3: GameState implementieren**

Ersetze den kompletten Inhalt von `flutter/lib/game_state.dart`:
```dart
class GameState {
  static const int targetUs = 1337000;

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
```

- [ ] **Step 4: Test ausführen — erwartet: PASS**

```bash
cd flutter && flutter test test/game_state_test.dart
```
Erwartet: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter/lib/game_state.dart flutter/test/game_state_test.dart
git commit -m "Add history and streak fields to GameState"
```

---

### Task 2: StorageService erstellen

**Files:**
- Create: `flutter/lib/storage_service.dart`
- Create: `flutter/test/storage_service_test.dart`

- [ ] **Step 1: Test schreiben**

Erstelle `flutter/test/storage_service_test.dart`:
```dart
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
```

- [ ] **Step 2: Test ausführen — erwartet: FAIL**

```bash
cd flutter && flutter test test/storage_service_test.dart
```
Erwartet: Kompilierfehler (`storage_service.dart` existiert noch nicht).

- [ ] **Step 3: StorageService implementieren**

Erstelle `flutter/lib/storage_service.dart`:
```dart
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
```

- [ ] **Step 4: Test ausführen — erwartet: PASS**

```bash
cd flutter && flutter test test/storage_service_test.dart
```
Erwartet: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter/lib/storage_service.dart flutter/test/storage_service_test.dart
git commit -m "Add StorageService with load/save and day-reset logic"
```

---

### Task 3: GameScreen koppeln

**Files:**
- Modify: `flutter/lib/screens/game_screen.dart`

- [ ] **Step 1: Import ergänzen**

In `flutter/lib/screens/game_screen.dart`, Import-Liste oben ergänzen:
```dart
import '../storage_service.dart';
```

- [ ] **Step 2: save() nach recordAttempt einfügen**

Im `_onTap`-Block, direkt nach `widget.gameState.recordAttempt(dev);`:
```dart
StorageService().save(widget.gameState);
```

Der vollständige `else if (_running)`-Block sieht dann so aus:
```dart
} else if (_running) {
  final now = DateTime.now();
  final ns = now.difference(_startTime!).inMicroseconds;
  _running = false;
  final dev = ns - GameState.targetUs;
  widget.gameState.recordAttempt(dev);
  StorageService().save(widget.gameState); // ← NEU

  setState(() => _elapsedUs = ns);

  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            elapsedUs: ns,
            devUs: dev,
            gameState: widget.gameState,
          ),
        ),
      );
    }
  });
}
```

- [ ] **Step 3: Alle Tests ausführen**

```bash
cd flutter && flutter test
```
Erwartet: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add flutter/lib/screens/game_screen.dart
git commit -m "Save to storage after each game attempt"
```

---

### Task 4: HomeScreen koppeln

**Files:**
- Modify: `flutter/lib/screens/home_screen.dart`

- [ ] **Step 1: Import und Feld ergänzen**

In `flutter/lib/screens/home_screen.dart`, Import ergänzen:
```dart
import '../storage_service.dart';
```

In `_HomeScreenState`, Feld nach der `GameState`-Deklaration:
```dart
final GameState gameState = GameState();
final _storage = StorageService(); // ← NEU
```

- [ ] **Step 2: _loadFromStorage-Methode hinzufügen**

Nach `dispose()`, neue Methode einfügen:
```dart
Future<void> _loadFromStorage() async {
  await _storage.load(gameState);
  if (mounted) setState(() {});
}
```

- [ ] **Step 3: _loadFromStorage in initState aufrufen**

Am Ende von `initState()`, nach dem Animations-Setup, einfügen:
```dart
_loadFromStorage();
```

Der vollständige `initState` sieht dann so aus:
```dart
@override
void initState() {
  super.initState();
  _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);
  _pulseAnim = Tween<double>(begin: 0.2, end: 0.45).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );
  _loadFromStorage(); // ← NEU
}
```

- [ ] **Step 4: Alle Tests ausführen**

```bash
cd flutter && flutter test
```
Erwartet: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter/lib/screens/home_screen.dart
git commit -m "Load persisted stats on HomeScreen init"
```

---

### Task 5: StatsScreen mit echten Daten

**Files:**
- Modify: `flutter/lib/screens/stats_screen.dart`

- [ ] **Step 1: _MockChart durch _RealChart ersetzen**

Am Ende von `stats_screen.dart`, die `_MockChart`-Klasse komplett durch `_RealChart` ersetzen:
```dart
class _RealChart extends StatelessWidget {
  final List<int> history;
  const _RealChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final display =
        history.length > 20 ? history.sublist(history.length - 20) : history;
    final data = display.map((d) => d.abs() / 1000).toList();
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((val) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: (val / maxVal) * 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8F55A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Chart-Widget im Build aktualisieren**

Im `StatsScreen.build`, den Chart-Body-Teil ersetzen:

```dart
// ALT:
gameState.tries > 0
    ? const Text(
        'Chart nach mehr Versuchen verfügbar',
        style: TextStyle(
          fontFamily: 'DMMono',
          fontSize: 10,
          color: Color(0xFF444444),
        ),
      )
    : const _MockChart(),

// NEU:
gameState.history.isNotEmpty
    ? _RealChart(history: gameState.history)
    : const Text(
        'Noch keine Versuche heute',
        style: TextStyle(
          fontFamily: 'DMMono',
          fontSize: 10,
          color: Color(0xFF444444),
        ),
      ),
```

- [ ] **Step 3: Streak-Card aktualisieren**

In der `GridView`-Kinder-Liste:
```dart
// ALT:
const _StatsCard(value: '7', label: 'TAGE STREAK 🔥'),

// NEU:
_StatsCard(value: '${gameState.streak}', label: 'TAGE STREAK 🔥'),
```

- [ ] **Step 4: Alle Tests ausführen**

```bash
cd flutter && flutter test
```
Erwartet: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter/lib/screens/stats_screen.dart
git commit -m "Show real chart data and streak in StatsScreen"
```
