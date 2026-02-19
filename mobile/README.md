# SoloTasks Mobile

Flutter mobile app for Android and iOS.

## Package Name

- Android/iOS bundle id root: `com.rameshwx.solotasks`

## Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Quality checks

```bash
flutter analyze
flutter test
```

## Main Navigation (Locked)

1. Today
2. Calendar
3. Tasks
4. Settings

Search/filter/smart-lists are under `Tasks` tab.
