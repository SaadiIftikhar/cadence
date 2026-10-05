# Cadence

An Android reminder app for routines you walk through one step at a time.

A reminder is either a single step or an ordered routine of them, each with its
own icon and optional countdown. Finishing a step moves you straight to the next
one still to do, so a morning routine runs without you having to find your place
in a list.

Everything stays on the device. The app holds **no `INTERNET` permission at
all** — it cannot reach a network even if it wanted to, and every release build
is checked for that.

## Download

**[Download the APK](https://github.com/SaadiIftikhar/cadence/releases/latest/download/Cadence-arm64.apk)** — arm64, Android 8+.

Sideloading, so Play Protect will warn you about an unrecognised developer.
The build is signed with Flutter's debug key for now.

## What it does

- Routines of ordered steps, or single-step reminders
- Per-step countdowns, with a ring that drains as the time runs out
- Real alarms: the phone's own alarm tone, ringing over the lock screen until
  dismissed, not silenced by unlocking
- A timer keeps running with the app closed — the deadline is scheduled, not
  held in memory
- An icon per step, picked from ~4300 Material Symbols and Tabler icons
- Home list ordered by time, finished reminders sinking to the bottom
- Calendar of which reminders repeat on which weekday
- Backup and restore to a `.zip`
- Today-only reminders retire themselves once their day is over

## Built with

Flutter, Riverpod, and drift (SQLite) with live queries. One Kotlin method
channel, which lets the alarm screen show over the keyguard while an alarm is
ringing and at no other time.

## Build it yourself

```bash
flutter pub get
flutter test
flutter build apk --release --split-per-abi --target-platform android-arm64 --no-tree-shake-icons
```

`--no-tree-shake-icons` is **not optional**. Icons are resolved by name at
runtime, which defeats Flutter's icon tree-shaking. Without the flag the build
still succeeds and every icon renders blank.

## Licence

[PolyForm Noncommercial 1.0.0](LICENSE).

Use it, study it, change it, share it — for anything that is not commercial.
Selling it, or using it to make money, is not permitted. Charities, schools and
public bodies count as noncommercial.
