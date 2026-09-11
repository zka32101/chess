# Chess Tactics Master - Build & Run Guide

## Prerequisites

### Required Software
- **Flutter**: 3.24.0 or higher
  - Download: https://flutter.dev/docs/get-started/install
  - Verify: `flutter --version`

- **Dart**: 3.x (included with Flutter)
  - Verify: `dart --version`

- **Git**: Latest version
  - Verify: `git --version`

### Platform-Specific Requirements

#### macOS / iOS
- Xcode 14.0 or higher
- CocoaPods package manager
- iOS 14+ deployment target

#### Linux / Android
- Android SDK (API level 21+)
- Android NDK
- Android Emulator or physical device (Android 7+)

#### Windows
- Windows 10 or higher
- Visual Studio 2019 or higher with C++ tools

## Setup Instructions

### 1. Clone Repository
```bash
git clone https://github.com/org-zka32101/chess.git
cd chess
```

### 2. Switch to Development Branch
```bash
git checkout claude/phase-d-stage-3-device-testing-wgxbuo
```

### 3. Install Flutter Dependencies
```bash
flutter pub get
```

### 4. Generate Code (Riverpod & Freezed)
```bash
dart run build_runner build
```

If you encounter conflicts:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Configure Firebase
Create `.env` file in project root with Firebase configuration:
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
```

Then run:
```bash
flutterfire configure
```

This will automatically generate `lib/firebase_options.dart`

### 6. Run Code Quality Checks
```bash
# Lint check
dart analyze lib/

# Format code
dart format lib/

# Fix formatting
dart format --fix lib/
```

## Running the App

### Option 1: Run on Connected Device
```bash
flutter run
```

### Option 2: Run on Emulator/Simulator
```bash
# Android Emulator
flutter emulators --launch android_emulator
flutter run

# iOS Simulator (macOS only)
open -a Simulator
flutter run
```

### Option 3: Run in Release Mode
```bash
flutter run --release
```

### Option 4: Run Specific Device
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Generate Coverage Report
```bash
flutter test --coverage
lcov --list coverage/lcov.info  # View coverage (macOS/Linux)
```

## Building for Release

### iOS (macOS only)
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
```

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# Or build AAB for Play Store
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

## Troubleshooting

### Common Issues

**Issue: "Flutter command not found"**
- Solution: Add Flutter to your PATH
  - macOS/Linux: Add `export PATH="$HOME/flutter/bin:$PATH"` to ~/.bashrc or ~/.zshrc
  - Windows: Add Flutter bin directory to System Environment Variables

**Issue: "Android license agreements not accepted"**
- Solution: Run `flutter doctor --android-licenses` and accept all licenses

**Issue: "CocoaPods dependency conflicts"**
- Solution: 
  ```bash
  cd ios
  pod repo update
  pod install
  cd ..
  ```

**Issue: "Build runner conflicts"**
- Solution:
  ```bash
  dart run build_runner clean
  dart run build_runner build --delete-conflicting-outputs
  ```

**Issue: "Firebase authentication not working"**
- Solution: Ensure `.env` file exists and `flutterfire configure` was run
  - Check `lib/firebase_options.dart` is properly generated

**Issue: "Sound service initialization warning"**
- Solution: This is non-critical; app runs without sound
  - Check platform-specific audio permissions in settings

### Debugging

Enable verbose logging:
```bash
flutter run -v
```

Debug output for specific issues:
```bash
flutter run -v --dart-define=DEBUG=true
```

## Development Workflow

### Standard Development Loop
1. Make code changes
2. Run `dart format --fix lib/` to format code
3. Run `dart analyze lib/` to check for issues
4. Run `flutter test` to run unit tests
5. Run `flutter run` to test on device
6. Commit changes: `git commit -m "feat: Add new feature"`
7. Push to development branch

### Adding New Dependencies
1. Edit `pubspec.yaml`
2. Run `flutter pub get`
3. Run `dart run build_runner build` if needed
4. Commit both `pubspec.yaml` and `pubspec.lock`

### Generating Code
```bash
# Generate all code
dart run build_runner build

# Watch for changes
dart run build_runner watch

# Delete and regenerate
dart run build_runner clean
dart run build_runner build
```

## Performance Optimization

### Profiling
```bash
flutter run --profile
# Then use DevTools to analyze performance
```

### Frame Rate Checking
```bash
flutter run --dart-define=ENABLE_PERFORMANCE_OVERLAY=true
```

## Next Steps

1. **Install Flutter** following platform-specific instructions
2. **Run the setup commands** to configure the project
3. **Test on a device** using `flutter run`
4. **Check the CLAUDE.md** for project architecture details
5. **Review existing screens** in `lib/src/screens/`
6. **Start implementing features** from Phase A onwards

## Support & Documentation

- **Flutter Docs**: https://flutter.dev/docs
- **Firebase Flutter**: https://firebase.flutter.dev
- **Riverpod Docs**: https://riverpod.dev
- **Chess Engine**: https://pub.dev/packages/chess

---

**Last Updated**: 2026-09-11  
**Project Status**: Build-Ready  
**Next Phase**: Phase A (Foundation) - Ready for Local Development
