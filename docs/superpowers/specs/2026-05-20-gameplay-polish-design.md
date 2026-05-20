# Gameplay-Polish — Design-Spec

**Datum:** 2026-05-20
**Scope:** Flutter-App (Android)
**Ziel:** Daily Challenge mit deterministischem Tagesziel, grade-basiertes haptisches Feedback und weiche Fade-Transitions zwischen Screens

---

## Übersicht

Drei unabhängige Verbesserungen in einem Paket:

1. **Daily Target** — `GameState.targetUs` wird vom konstanten Wert zum täglich wechselnden, deterministisch berechneten Ziel
2. **Haptic Patterns** — Das Ergebnis-Feedback variiert je nach erreichten Grade statt immer `mediumImpact`
3. **Fade Transitions** — Alle `MaterialPageRoute`-Aufrufe werden durch einen `FadePageRoute`-Wrapper ersetzt

---

## Dateiübersicht

| Datei | Aktion | Zweck |
|-------|--------|-------|
| `flutter/lib/game_state.dart` | Modify | `targetUs` als Getter, `targetForDate()` + Konstanten |
| `flutter/lib/utils/fade_page_route.dart` | **Create** | `FadePageRoute<T>` Wrapper |
| `flutter/lib/screens/home_screen.dart` | Modify | `FadePageRoute` für Game + Stats |
| `flutter/lib/screens/game_screen.dart` | Modify | `FadePageRoute` für Result |
| `flutter/lib/screens/result_screen.dart` | Modify | Grade-Haptic + `FadePageRoute` für Game + Home |
| `flutter/test/game_state_test.dart` | Modify | Tests für `targetForDate()` |

---

## 1. Daily Target

### Implementierung

`targetUs` wechselt von `const` zu einem berechneten Getter. Alle bestehenden `GameState.targetUs`-Aufrufe bleiben unverändert.

```dart
static const int _targetMin = 700000;       // 0.7s in μs
static const int _targetMax = 2000000;      // 2.0s in μs
static const int _lcgMultiplier = 1664525;
static const int _lcgIncrement = 1013904223;

static int get targetUs => targetForDate(DateTime.now());

static int targetForDate(DateTime date) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final hash = (seed * _lcgMultiplier + _lcgIncrement) & 0x7FFFFFFF;
  return _targetMin + (hash % (_targetMax - _targetMin));
}
```

**LCG-Hash:** Linear Congruential Generator — deterministisch, kein Server. Alle Spieler haben täglich dasselbe Ziel. Zielbereich: 0.7s bis 2.0s.

### Auswirkungen auf StorageService

Keine. Das Tagesziel wird immer live berechnet, nicht gespeichert. Der bestehende Tages-Reset-Mechanismus bleibt unverändert.

### Tests

```dart
test('targetForDate returns same value for same date', () {
  final date = DateTime(2026, 5, 20);
  expect(GameState.targetForDate(date), GameState.targetForDate(date));
});

test('targetForDate returns different values for different dates', () {
  final d1 = DateTime(2026, 5, 20);
  final d2 = DateTime(2026, 5, 21);
  expect(GameState.targetForDate(d1), isNot(GameState.targetForDate(d2)));
});

test('targetForDate is within valid range', () {
  final target = GameState.targetForDate(DateTime(2026, 5, 20));
  expect(target, greaterThanOrEqualTo(700000));
  expect(target, lessThan(2000000));
});
```

---

## 2. Haptic Patterns

In `ResultScreen.initState`, das generische `HapticFeedback.mediumImpact()` ersetzen:

```dart
final absMs = widget.devUs.abs() / 1000;
if (absMs == 0) {
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 80), HapticFeedback.heavyImpact);
} else if (absMs <= 20) {
  HapticFeedback.heavyImpact();   // UNMÖGLICH
} else if (absMs <= 80) {
  HapticFeedback.mediumImpact();  // STARK
} else {
  HapticFeedback.lightImpact();   // SOLIDE + ÜBEN
}
```

- `absMs == 0`: doppeltes `heavyImpact` mit 80ms Abstand — spürbar anders als einmaliges, kein `async` in `initState` nötig
- Schwellwerte (20ms, 80ms) spiegeln `GameState.gradeLabel()` exakt wider

---

## 3. Fade Transitions

### FadePageRoute

Neue Datei `flutter/lib/utils/fade_page_route.dart`:

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

### Ersetze MaterialPageRoute

| Datei | Methode/Stelle | Navigation |
|-------|---------------|------------|
| `home_screen.dart` | `_goToGame()` | push → GameScreen |
| `home_screen.dart` | `_goToStats()` | push → StatsScreen |
| `game_screen.dart` | `_onTap else if (_running)` | pushReplacement → ResultScreen |
| `result_screen.dart` | NOCHMAL-Button | pushReplacement → GameScreen |
| `result_screen.dart` | HOME-Button | pushAndRemoveUntil → HomeScreen |

`StatsScreen` nutzt `Navigator.pop()` — kein `PageRoute`-Aufruf, keine Änderung nötig.

---

## Was nicht in scope ist

- Sound-Effekte
- iOS-Support
- Firebase
- Änderungen an der Web-Version (`docs/`)
