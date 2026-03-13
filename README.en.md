# GymTracker

Language: [Español](README.md) | English

A Flutter-based workout tracking app to log weights, monitor weekly progress, and keep training history in a simple and practical way.

[![Web Demo](https://img.shields.io/badge/Web%20Demo-Try%20now-00C896?style=for-the-badge)](https://paimilla.github.io/app-gimnacio/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

## Demo

- Live web demo: https://paimilla.github.io/app-gimnacio/
- If it does not load immediately, refresh with Ctrl+F5.

## What you can do in the app

- Plan workouts by day and muscle group.
- Log weight, reps, and notes per exercise.
- Compare progress with friends.
- Visualize progress with charts.
- Save body transformation photos.
- Keep data locally without a backend.

## Tech stack

- Flutter
- Dart
- SharedPreferences
- FL Chart
- Image Picker
- Google Fonts
- URL Launcher

## Screenshots

<p align="center">
  <img src="flutter_application_1/assets/icons/Screenshot_1773367574.png" alt="Home screen" width="220" />
  <img src="flutter_application_1/assets/icons/Screenshot_1773367584.png" alt="Workout details" width="220" />
  <img src="flutter_application_1/assets/icons/Screenshot_1773367588.png" alt="Progress and statistics" width="220" />
  <img src="flutter_application_1/assets/icons/Screenshot_1773367635.png" alt="Settings and profile" width="220" />
</p>

## Quick start (local)

Requirements:

- Flutter 3.x
- Dart SDK 3.x

Run the project:

```bash
cd flutter_application_1
flutter pub get
flutter run
```

Run web locally:

```bash
cd flutter_application_1
flutter run -d chrome
```

## Current structure

```text
app-gimnacio/
├── README.md
├── README.en.md
└── flutter_application_1/
    ├── lib/
    │   └── main.dart
    ├── assets/
    ├── android/
    ├── ios/
    ├── web/
    └── pubspec.yaml
```

Note: most logic currently lives in a single file (lib/main.dart). A future improvement is to split architecture into folders like pages, models, and services.

## Suggested roadmap

- Layer-based refactor (pages, models, services).
- Export training history.
- Authentication and cloud sync.
- Coach mode for multi-user tracking.

## About the developer

Felipe Paimilla

Computer Civil Engineer, Universidad de Playa Ancha.

Experience:

- Process and systems automation.
- Flutter application development.
- CMS platform migration.
- Technical support and troubleshooting.

Stack: Flutter, Dart, Backend, and Automation.

GitHub:

- https://github.com/Paimilla
- https://github.com/Fpaimilla

LinkedIn:

- https://www.linkedin.com/in/felipe-paimilla-4000a2206/

## Feedback

If you find a bug or want to suggest an improvement, open an issue in the repository.

---

Built with Flutter by Felipe Paimilla.
