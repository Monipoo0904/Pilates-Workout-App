# PilatesTimer

PilatesTimer is an iOS + watchOS app for managing Pilates workouts, timing class segments, and syncing a class plan between the phone and Apple Watch.

## Features

- Manage Pilates class structure and exercise items
- Track timing and progression during sessions
- Import class data from JSON or clipboard-friendly formats
- Mirror state between iPhone and Apple Watch
- Run as a shared SwiftUI app with both mobile and wearable targets

## Project structure

- `Shared/` — shared models and logic used by both app targets
- `iOS/` — iPhone app code
- `watchOS/` — Apple Watch app code
- `Tests/` — test targets and validation files
- `PilatesTimerProject.xcodeproj` — Xcode project definition

## Requirements

- Xcode 15 or later
- iOS 17+ and watchOS 10+
- Apple developer account for device signing and provisioning

## Opening in Xcode

1. Open `PilatesTimerProject.xcodeproj` in Xcode.
2. Select the appropriate app target.
3. Choose your team and bundle identifier.
4. Build and run on a simulator or connected device.

## Publishing to GitHub

After the project is ready, create a new empty GitHub repository and add it as the remote:

```bash
git remote add origin git@github.com:<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
git branch -M main
git push -u origin main
```

If you use HTTPS instead of SSH:

```bash
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
```

## License

This project currently does not include a license file. Add one before distributing publicly if you want to define usage terms.
