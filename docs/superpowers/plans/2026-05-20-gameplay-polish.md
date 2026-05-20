# Gameplay-Polish Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Daily Challenge mit deterministischem Tagesziel, grade-basiertes haptisches Feedback und weiche Fade-Transitions zwischen allen Screens.

**Architecture:** Drei unabhängige Tasks: (1) `GameState.targetUs` wird vom Constant zum täglich berechneten Getter via LCG-Hash, (2) `ResultScreen.initState` wählt Haptic-Intensität nach Grade, (3) ein neuer `FadePageRoute`-Wrapper ersetzt alle `MaterialPageRoute`-Aufrufe.

**Tech Stack:** Flutter, dart:core (keine neuen Dependencies)

---

## Dateiübersicht

| Datei | Aktion | Zweck |
|-------|--------|-------|
| `flutter/lib/game_state.dart` | Modify | `targetUs` als Getter, `targetForDate()` + private Konstanten |
| `flutter/test/game_state_test.dart` | Modify | Tests für `targetForDate()` |
| `flutter/lib/screens/result_screen.dart` | Modify | Grade-basiertes Haptic Feedback |
| `flutter/lib/utils/fade_page_route.dart` | **Create** | `FadePageRoute<T>` Wrapper |
| `flutter/lib/screens/home_screen.dart` | Modify | `FadePageRoute` in `_goToGame()` + `_goToStats()` |
| `flutter/lib/screens/game_screen.dart` | Modify | `FadePageRoute` für ResultScreen-Navigation |
| `flutter/lib/screens/result_screen.dart` | Modify | `FadePageRoute` für NOCHMAL + HOME |

---

### Task 1: Daily Target in GameState

**Files:**
- Modify: `flutter/lib/game_state.dart`
- Modify: `flutter/test/game_state_test.dart`

- [ ] **Step 1: Tests für targetForDate schreiben**

Öffne `flutter/test/game_state_test.dart` und füge eine neue `group`-Sektion nach dem bestehenden `group('GameState', ...)` ein:

```dart
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
```

Die vollständige `flutter/test/game_state_test.dart` sieht dann so aus:

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
```

- [ ] **Step 2: Test ausführen — erwartet: FAIL**

```bash
cd flutter && flutter test test/game_state_test.dart
```
Erwartet: Kompilierfehler (`targetForDate` existiert noch nicht).

- [ ] **Step 3: GameState implementieren**

Ersetze den kompletten Inhalt von `flutter/lib/game_state.dart`:

```dart
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
```

- [ ] **Step 4: Test ausführen — erwartet: PASS**

```bash
cd flutter && flutter test test/game_state_test.dart
```
Erwartet: All 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter/lib/game_state.dart flutter/test/game_state_test.dart
git commit -m "Add daily target via LCG hash to GameState"
```

---

### Task 2: Grade-basiertes Haptic Feedback

**Files:**
- Modify: `flutter/lib/screens/result_screen.dart`

- [ ] **Step 1: initState in ResultScreen anpassen**

In `flutter/lib/screens/result_screen.dart`, ersetze in `_ResultScreenState.initState()` die Zeile:

```dart
HapticFeedback.mediumImpact();
```

durch:

```dart
final absMs = widget.devUs.abs() / 1000;
if (absMs == 0) {
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 80), HapticFeedback.heavyImpact);
} else if (absMs <= 20) {
  HapticFeedback.heavyImpact();
} else if (absMs <= 80) {
  HapticFeedback.mediumImpact();
} else {
  HapticFeedback.lightImpact();
}
```

Der vollständige `initState` sieht dann so aus:

```dart
@override
void initState() {
  super.initState();
  final absMs = widget.devUs.abs() / 1000;
  if (absMs == 0) {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80), HapticFeedback.heavyImpact);
  } else if (absMs <= 20) {
    HapticFeedback.heavyImpact();
  } else if (absMs <= 80) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.lightImpact();
  }
  _barController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  _barAnim = CurvedAnimation(
    parent: _barController,
    curve: const ElasticOut(period: 0.5),
  );
  Future.delayed(const Duration(milliseconds: 100), () {
    _barController.forward();
  });
}
```

- [ ] **Step 2: Alle Tests ausführen**

```bash
cd flutter && flutter test
```
Erwartet: All tests pass (keine neuen Tests — Haptic ist Hardware-API).

- [ ] **Step 3: Commit**

```bash
git add flutter/lib/screens/result_screen.dart
git commit -m "Add grade-based haptic feedback on result screen"
```

---

### Task 3: FadePageRoute erstellen und einbinden

**Files:**
- Create: `flutter/lib/utils/fade_page_route.dart`
- Modify: `flutter/lib/screens/home_screen.dart`
- Modify: `flutter/lib/screens/game_screen.dart`
- Modify: `flutter/lib/screens/result_screen.dart`

- [ ] **Step 1: utils-Verzeichnis erstellen und FadePageRoute implementieren**

Erstelle `flutter/lib/utils/fade_page_route.dart`:

```dart
import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({required Widget page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        );
}
```

- [ ] **Step 2: HomeScreen anpassen**

In `flutter/lib/screens/home_screen.dart`:

Import ergänzen (nach den bestehenden Imports):
```dart
import '../utils/fade_page_route.dart';
```

Methode `_goToGame()` ersetzen:
```dart
void _goToGame() async {
  final result = await Navigator.push<int>(
    context,
    FadePageRoute(page: GameScreen(gameState: gameState)),
  );
  if (result != null) setState(() {});
}
```

Methode `_goToStats()` ersetzen:
```dart
void _goToStats() {
  Navigator.push(
    context,
    FadePageRoute(page: StatsScreen(gameState: gameState)),
  );
}
```

- [ ] **Step 3: GameScreen anpassen**

In `flutter/lib/screens/game_screen.dart`:

Import ergänzen:
```dart
import '../utils/fade_page_route.dart';
```

Im `_onTap`-Block, den `Navigator.pushReplacement`-Aufruf ersetzen:
```dart
Navigator.pushReplacement(
  context,
  FadePageRoute(
    page: ResultScreen(
      elapsedUs: ns,
      devUs: dev,
      gameState: widget.gameState,
    ),
  ),
);
```

Der vollständige `else if (_running)`-Block sieht dann so aus:
```dart
} else if (_running) {
  final now = DateTime.now();
  final ns = now.difference(_startTime!).inMicroseconds;
  _running = false;
  final dev = ns - GameState.targetUs;
  widget.gameState.recordAttempt(dev);
  StorageService().save(widget.gameState);

  setState(() => _elapsedUs = ns);

  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        FadePageRoute(
          page: ResultScreen(
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

- [ ] **Step 4: ResultScreen anpassen**

In `flutter/lib/screens/result_screen.dart`:

Import ergänzen:
```dart
import '../utils/fade_page_route.dart';
```

NOCHMAL-Button `onTap` ersetzen:
```dart
onTap: () {
  Navigator.pushReplacement(
    context,
    FadePageRoute(page: GameScreen(gameState: widget.gameState)),
  );
},
```

HOME-Button `onTap` ersetzen:
```dart
onTap: () {
  Navigator.pushAndRemoveUntil(
    context,
    FadePageRoute(page: const HomeScreen()),
    (route) => false,
  );
},
```

- [ ] **Step 5: Alle Tests ausführen**

```bash
cd flutter && flutter test
```
Erwartet: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add flutter/lib/utils/fade_page_route.dart flutter/lib/screens/home_screen.dart flutter/lib/screens/game_screen.dart flutter/lib/screens/result_screen.dart
git commit -m "Add FadePageRoute and replace all MaterialPageRoute calls"
```
