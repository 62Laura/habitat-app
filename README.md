# Habitat App - Habit & Goal Tracker



**Habitat App** v2.0.0+1 is a cross-platform Flutter habit and goal tracking app with Firebase backend. Refactored Habit Tracker with improved state management (Riverpod) and UI/UX. Features gentle growth-themed UI and real-time sync for daily habits and long-term goals.

## ✨ Features

- **Authentication**: Secure email/password login/signup via Firebase Auth
- **Home Dashboard**: Overview stats for habits and goals progress
- **Habits Management**: Create, read, update, delete habits with real-time sync
- **Goals Management**: Track goals with title, description, target value, and action steps
- **Settings**: Light/dark theme toggle
- **Multi-platform**: Android, iOS, macOS, Linux, Windows, Web
- **English UI**: Static English strings throughout
- **Real-time Data**: Firestore for habits/goals sync across devices

## 🛠️ Tech Stack

| Category | Technologies |
|----------|--------------|
| Framework | Flutter (Dart) |
| State Management | Riverpod 2.4 |
| Backend | Firebase Auth, Firestore ('habitat-app-17df5') |
| Local Storage | SharedPreferences |
| UI/Theme | Material 3, Custom green growth theme, Google Fonts |
| Utils | timezone |
| Additional | cached_network_image, pin_code_fields (forms) |

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry, Firebase init, Riverpod
├── firebase_options.dart     # Multi-platform Firebase config
├── models/models.dart         # Data models (Habit, Goal)
├── providers/                # Riverpod notifiers: auth, habits, goals, theme
├── services/                 # Business logic: auth_service, habit_service, goal_service
├── screens/                  # UI: home/, habit/, goal/, auth/, settings_screen
├── theme/app_theme.dart      # Light/dark Material3 themes (greens)
├── widgets/                  # Reusable: auth_gate, common_widgets
```

**Flow**: AuthGate → HomeScreen (tabs: Home/Habits/Goals/Settings) → CRUD forms with provider updates → Firestore sync.

## 📱 Screenshots

<!-- Add screenshots: home dashboard, habit list, goal edit, settings -->

## 🚀 Quick Start

### Prerequisites
- Flutter SDK >=3.10
- Firebase project (use 'habitat-app-17df5' or clone config)
- Android Studio/Xcode for emulators

### Setup
```bash
cd habita_app
flutter pub get
flutter run
```

### Firebase
- Download `google-services.json` (Android), `GoogleService-Info.plist` (iOS/macOS)
- Deploy rules: `cd habita_app && ./deploy_firestore_rules.sh`
- Update `firebase_options.dart` if new project

## 🔧 Local Development

- **Analyze**: `flutter analyze`
- **Test**: `flutter test`
- **Build**: `flutter build apk` / `flutter build ios`

## 🚀 Roadmap / Future Features

- [ ] Garden growth metaphor (visual plants for habits)
- [ ] Accountability circles/groups
- [ ] Charts & insights (fl_chart)
- [ ] Proverbs integration
- [ ] Streak-free progress (pause/resume)
- [ ] Push notifications
- [x] Remove multi-language support (English-only complete)
- [ ] Rename project directory/pubspec from 'habita_app'/'habit_app' → 'habitat_app'
- [ ] Add screenshots to README
- [ ] Fix minor linter warnings (withOpacity, const prefs)

## 🤝 Contributing

1. Fork & clone
2. `cd habita_app && flutter pub get`
3. Create feature branch
4. PR to `main`

See TODOs in `habita_app/TODO.md`

## 📄 License

MIT License.

## 👥 Acknowledgments

Built by ALU students. Props to Flutter & Firebase communities.

---

*\"Small daily improvements create outstanding results\" - Habit Tracker Wisdom*
