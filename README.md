# Legder

Legder is a minimal Flutter app for seeing time plainly.

It shows year progress, optional life progress, and one short reflection entry per day. There are no accounts, cloud sync, streaks, goals, notifications, or motivational prompts. Data stays local unless the user exports it manually.

## Features

- Year progress screen with percent passed, days left, current date/time, and a compact daily reflection entry.
- Reflection log with a year grid, entries list, weekly/monthly factual summaries, and "a year ago" context when writing today's entry.
- Local reflection export/import as JSON, using the native share sheet and file picker.
- Optional life progress screen with birthdate and life expectancy inputs.
- Lightweight first-run onboarding in context, not as a tutorial or blocking setup flow.
- Android home screen widget with year progress, days left, date, and a resizable year overview.
- Custom app and widget icons from `assets/icon.png` and `assets/widget-icon.jpg`.

## Data

Reflection and life-progress data are stored locally on the device.

Use the Reflections screen menu to:

- Export entries to a JSON backup file.
- Import a previously exported JSON backup file.

Import validates the file first and merges entries by date.

## Android Widget

The Android widget is read-only.

- Small size: percent, days left, date, and progress bar.
- Larger resized size: adds the year overview grid.
- Tap: opens the app to the Year Progress screen.
- Updates: on app open/resume and through a daily WorkManager task.

After installing a new build, Android may cache the old widget preview or launcher icon. Re-add the widget or reinstall cleanly if the launcher does not refresh immediately.

## Run Locally

```sh
flutter pub get
flutter run
```

For Android debug APK:

```sh
flutter build apk --debug --target-platform android-arm64 --split-per-abi
```

The generated APK is usually under:

```text
build/app/outputs/flutter-apk/
```

## Tests

```sh
flutter analyze
flutter test
```

## Project Notes

- Main Flutter entry point: `lib/main.dart`
- Year/date logic: `lib/utils/year_progress.dart`
- Reflection storage and import/export: `lib/services/reflection_service.dart`
- Android widget provider: `android/app/src/main/kotlin/com/example/progressbar/YearProgressWidgetProvider.kt`
- Android widget layout: `android/app/src/main/res/layout/year_progress_widget.xml`

The app display name is `Legder`. The Dart package name is still `progressbar` to avoid changing import paths and bundle identifiers.
