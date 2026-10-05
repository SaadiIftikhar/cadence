# Cadence

An Android reminder app for routines you walk through one step at a time.

A reminder is either a single step or an ordered routine of them. Each step can
carry its own icon and countdown timer. Finishing a step moves you straight to
the next one still to do, so a morning routine runs without you having to find
your place in a list.

Everything is stored on the device. The app holds **no `INTERNET` permission at
all** — it cannot talk to a network even if it wanted to, which is checked
against every release build.

## Features

- **Routines and single steps.** A routine is an ordered list; Done on one step
  advances to the next one left to do.
- **Per-step timers.** A countdown with a ring that drains as the time runs out,
  and a chime when it finishes.
- **Real alarms.** An alarm rings with the phone's own alarm tone, keeps
  ringing, and opens a full-screen screen over the lock screen that has to be
  dismissed — unlocking the phone is not enough to silence it.
- **Notifications or alarms, per reminder**, with exact-alarm scheduling where
  the OS allows it.
- **Icon per step**, chosen from Material Symbols and Tabler sets (~4300 icons,
  searchable).
- **Home ordered by time**, with finished reminders dropping to the bottom.
- **Calendar** of which reminders repeat on which weekday.
- **Backup and restore** to a `.zip` holding a JSON manifest and any images, so
  moving to a new phone keeps everything but your progress.
- **Today-only reminders** retire themselves once their day has passed.

## Build

Requires the Flutter SDK and an Android toolchain.

```bash
flutter pub get
flutter test
flutter build apk --release --split-per-abi --target-platform android-arm64 --no-tree-shake-icons
```

`--no-tree-shake-icons` is **not optional**. The icon picker resolves icons by
name at runtime, which defeats Flutter's icon tree-shaking. Leaving the flag off
still produces a working build, but every icon renders blank or as `?`.

The release build is currently signed with the debug key (Flutter's default). To
publish, add a keystore and point `android/app/build.gradle.kts` at it; `*.jks`
and `key.properties` are gitignored.

## Architecture

- **Flutter** with **Riverpod** for state and **drift** (SQLite) for storage.
  Screens watch live queries, so progress made on one screen shows up on the
  others without manual refreshes.
- `lib/data/` — schema, providers, and the pure functions the UI rules are built
  from (`nextIncompleteStep`, `orderedForHome`, `remindersOnDay`,
  `withoutLapsedOneOffs`, `timerRingFraction`). These are pure so they can be
  tested directly rather than through a widget.
- `lib/screens/` — one file per screen.
- `lib/widgets/` — the shared pieces: pill tiles, segmented progress outlines,
  the timer pill, hint callouts.
- `lib/services/` — notification scheduling and the timer chime.
- `lib/l10n/` — every user-facing string, in `app_en.arb`. Nothing in the UI
  holds its own copy, so adding a language is a matter of adding one `.arb`
  file. The data layer names failures with an enum rather than a sentence, so
  it never has to reach for a language it cannot see.
- `android/app/src/main/kotlin/` — a single method channel, which lets the alarm
  screen show over the keyguard only while an alarm is actually ringing.

## Tests

```bash
flutter test
```

Covers the ordering and scheduling rules, backup round-trips, the reminder and
step editors' validation, navigation through a routine, and the calendar's
layout. Animation tests assert direction and distance rather than just that a
widget arrived.

## Licence

[MIT](LICENSE).
