# Datenpersistenz — Design-Spec

**Datum:** 2026-05-20  
**Scope:** Flutter-App (Android)  
**Ziel:** Spielerdaten zwischen Sessions erhalten, Tages-Reset und Streak-Tracking implementieren

---

## Übersicht

Einführung eines `StorageService`, der alle SharedPreferences-Aufrufe kapselt. `GameState` bleibt reine In-Memory-Logik. `HomeScreen` lädt beim Start aus dem Storage und speichert nach jedem Spiel.

Gleichzeitig wird ein bestehender Bug behoben: `pushAndRemoveUntil` (Home-Button im Result-Screen) erzeugt eine neue `HomeScreen`-Instanz und verliert damit den aktuellen In-Memory-State. Mit Storage-backed Initialisierung lädt `initState()` die Daten neu und der State bleibt erhalten.

---

## Datenschema (SharedPreferences)

| Key | Typ | Inhalt |
|-----|-----|--------|
| `best_deviation` | `int` | Beste Abweichung in μs (kann negativ sein); fehlt wenn noch kein Versuch |
| `tries_today` | `int` | Anzahl Versuche heute; 0 bei Tages-Reset |
| `history_today` | `String` | JSON-Array der letzten max. 50 Abweichungen in μs |
| `last_played_date` | `String` | Datum des letzten Versuchs im Format `YYYY-MM-DD` |
| `streak` | `int` | Aufeinanderfolgende Spieltage |

---

## Architektur

```
flutter/lib/
  game_state.dart        ← +history, +streak; kein Persistence-Code
  storage_service.dart   ← NEU: kapselt SharedPreferences
  screens/
    home_screen.dart     ← load() bei initState, save() nach Spiel
    stats_screen.dart    ← Chart und Streak aus echten Daten
```

**Datenfluss:**
1. App startet → `HomeScreen.initState()` → `StorageService.load(gameState)` → `setState()`
2. Spiel endet → `_goToGame()` kehrt zurück → `StorageService.save(gameState)` → `setState()`
3. "HOME" aus Result → `pushAndRemoveUntil` → neue `HomeScreen` → `initState()` lädt aus Storage ✓

---

## StorageService

```dart
class StorageService {
  Future<void> load(GameState state) async { ... }
  Future<void> save(GameState state) async { ... }
}
```

**`load()` — Tages-Reset-Logik:**
- SharedPreferences-Instanz holen
- `last_played_date` lesen; wenn ≠ heute (oder fehlt): `best_deviation`, `tries_today`, `history_today` ignorieren (Tagesdaten verfallen)
- Streak bleibt beim Reset erhalten (wird erst beim nächsten `save()` neu berechnet)
- Geladene Werte in `GameState` schreiben

**`save()` — Streak-Update:**
- `last_played_date` prüfen:
  - War es gestern → `streak++`
  - War es heute → `streak` unverändert
  - War es länger her (oder fehlt) → `streak = 1`
- Alle Felder in SharedPreferences schreiben, `last_played_date` auf heute setzen

---

## GameState-Erweiterungen

Zwei neue Felder, `recordAttempt` wird erweitert:

```dart
List<int> history = [];  // Abweichungen in μs, chronologisch, max. 50 Einträge
int streak = 0;

void recordAttempt(int deviationNs) {
  tries++;
  if (bestDeviation == null || deviationNs.abs() < bestDeviation!.abs()) {
    bestDeviation = deviationNs;
  }
  history.add(deviationNs);
  if (history.length > 50) history.removeAt(0);
}
```

Kein async-Code in `GameState`. Der Service setzt die Felder direkt nach dem Laden.

---

## Screen-Änderungen

### HomeScreen

```dart
// initState
final _storageService = StorageService();
await _storageService.load(gameState);
setState(() {});

// _goToGame
final result = await Navigator.push(...);
if (result != null) {
  await _storageService.save(gameState);
  setState(() {});
}
```

`HomeScreen` wird zu `StatefulWidget` mit `async initState()` (via `WidgetsBinding.instance.addPostFrameCallback` oder direktem `async` Aufruf).

### StatsScreen

- Chart (`_MockChart` entfernen): `gameState.history` direkt verwenden; zeigt absolute Abweichungen in ms (`dev.abs() / 1000`)
- Bei leerem `history`: Platzhaltertext wie bisher
- Streak-Card: `'${gameState.streak}'` statt hardcodiertem `'7'`

### Was bleibt unverändert

- Rang `#4.821` bleibt hardcodiert — braucht Firebase-Integration (separates Feature)
- Web-Version (`docs/`) ist nicht Teil dieses Scopes

---

## Was nicht in scope ist

- Firebase Leaderboard (eigenes Feature)
- Web-Version (eigene Codebase)
- iOS-Build-Pipeline
