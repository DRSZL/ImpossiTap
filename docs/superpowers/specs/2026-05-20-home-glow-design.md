# Home Screen Glow — Design-Spec

**Datum:** 2026-05-20
**Scope:** `flutter/lib/screens/home_screen.dart` (nur dieser Screen)
**Ziel:** Subtiler Neon-Glow-Look für den Home Screen — stärkere Atmosphäre ohne visuellen Lärm

---

## Übersicht

Sechs gezielte Anpassungen an bestehenden Widgets. Keine neuen Widgets, keine Änderungen an Logik oder anderen Screens.

| Element | Änderung |
|---------|----------|
| Hintergrundfarbe | `#0A0A0A` → `#080808` |
| Hintergrund-Aura | Zwei überlagerte radiale Gradienten hinter dem Button |
| Play-Button | 4-Layer `boxShadow` statt 1 |
| Zielzahl | `shadows` in Lime |
| Stat-Boxen | Lime-getönter Border + Hintergrund + glühende Werte |
| Nav-Tab aktiv | `shadows` auf aktivem Label |
| Subtexte | `#555555` → `#383838` (mehr Kontrast zu leuchtenden Elementen) |

---

## Detailspezifikation

### 1. Hintergrundfarbe

```dart
// vorher
backgroundColor: const Color(0xFF0A0A0A),

// nachher
backgroundColor: const Color(0xFF080808),
```

### 2. Hintergrund-Aura hinter dem Button

Der `Stack` bekommt zwei neue `Positioned`-Widgets **hinter** dem Play-Button (vor dem Button einfügen):

```dart
// Innerer Glow
Positioned(
  bottom: 95,
  left: 0,
  right: 0,
  child: Center(
    child: Container(
      width: 320,
      height: 320,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x0AC8F55A), Colors.transparent],
          stops: [0.0, 1.0],
        ),
      ),
    ),
  ),
),
// Äußerer diffuser Glow
Positioned(
  bottom: 60,
  left: 0,
  right: 0,
  child: Center(
    child: Container(
      width: 500,
      height: 500,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x04C8F55A), Colors.transparent],
          stops: [0.0, 1.0],
        ),
      ),
    ),
  ),
),
```

**Hinweis:** `0x0A` = ~4% Opacity, `0x04` = ~1.5% Opacity. Werte auf Gerät prüfen — OLED-Displays zeigen Glows stärker als LCD.

### 3. Play-Button: 4-Layer boxShadow

```dart
// vorher
boxShadow: [
  BoxShadow(
    color: const Color(0xFFC8F55A).withOpacity(_pulseAnim.value),
    blurRadius: 60,
    spreadRadius: 10,
  ),
],

// nachher
boxShadow: [
  BoxShadow(
    color: const Color(0xFFC8F55A).withOpacity(0.12),
    blurRadius: 0,
    spreadRadius: 1,
  ),
  BoxShadow(
    color: const Color(0xFFC8F55A).withOpacity(_pulseAnim.value * 0.55),
    blurRadius: 25,
    spreadRadius: 0,
  ),
  BoxShadow(
    color: const Color(0xFFC8F55A).withOpacity(_pulseAnim.value * 0.25),
    blurRadius: 60,
    spreadRadius: 0,
  ),
  BoxShadow(
    color: const Color(0xFFC8F55A).withOpacity(_pulseAnim.value * 0.12),
    blurRadius: 110,
    spreadRadius: 0,
  ),
],
```

Der Puls-Effekt bleibt erhalten — nur Layer 1 (Ring) ist fix, Layer 2–4 pulsieren mit dem `_pulseAnim`-Wert.

### 4. Zielzahl: Text-Glow

```dart
// vorher
style: const TextStyle(
  fontFamily: 'BebasNeue',
  fontSize: 46,
  color: Color(0xFFC8F55A),
  letterSpacing: 1,
  height: 1,
),

// nachher
style: const TextStyle(
  fontFamily: 'BebasNeue',
  fontSize: 46,
  color: Color(0xFFC8F55A),
  letterSpacing: 1,
  height: 1,
  shadows: [
    Shadow(color: Color(0x47C8F55A), blurRadius: 20),
    Shadow(color: Color(0x1AC8F55A), blurRadius: 50),
  ],
),
```

**Hex-Opacity:** `0x47` = 28%, `0x1A` = 10%.

### 5. Stat-Boxen: Lime-Tint

In `_StatBox.build()`:

```dart
// vorher
decoration: BoxDecoration(
  color: const Color(0xFF141414),
  border: Border.all(color: const Color(0xFF222222)),
),

// nachher
decoration: BoxDecoration(
  color: const Color(0x04C8F55A),
  border: Border.all(color: const Color(0x0FC8F55A)),
),
```

Stat-Wert (bisher `Colors.white`) bekommt einen subtilen Glow:

```dart
// vorher
style: const TextStyle(
  fontFamily: 'DMMono',
  fontSize: 14,
  color: Colors.white,
  fontWeight: FontWeight.w500,
),

// nachher
style: const TextStyle(
  fontFamily: 'DMMono',
  fontSize: 14,
  color: Colors.white,
  fontWeight: FontWeight.w500,
  shadows: [Shadow(color: Color(0x2EC8F55A), blurRadius: 8)],
),
```

**Hex-Opacity:** `0x0F` = 6%, `0x04` = 1.5%, `0x2E` = 18%.

### 6. Aktiver Nav-Tab: Text-Glow

In `_NavTab.build()`:

```dart
// vorher
color: active ? const Color(0xFFC8F55A) : const Color(0xFF555555),

// nachher
color: active ? const Color(0xFFC8F55A) : const Color(0xFF555555),
shadows: active
    ? [const Shadow(color: Color(0x33C8F55A), blurRadius: 6)]
    : null,
```

**Hex-Opacity:** `0x33` = 20%.

### 7. Subtexte dunkler

Alle `color: Color(0xFF555555)` im Home Screen die **nicht** interaktiv sind (Tagline, Labels, Unit):

```dart
// vorher
color: const Color(0xFF555555),

// nachher
color: const Color(0xFF383838),
```

Betrifft: Tagline `YOU CAN'T. BUT TRY ANYWAY.`, Label `HEUTIGES ZIEL`, Unit `MIKROSEKUNDEN`.
Der inaktive Nav-Tab bleibt bei `#555555` (muss lesbar bleiben).

---

## Was nicht in scope ist

- Game Screen, Result Screen, Stats Screen — keine Änderungen
- Animationslogik — `_pulseController` und `_pulseAnim` bleiben unverändert
- Neue Widgets oder Layoutänderungen
