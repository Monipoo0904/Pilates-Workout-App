# Coding Notes

This document captures the current architecture, conventions, and implementation notes for the PilatesTimer project so future contributors can continue building it efficiently.

## Project overview

The app is structured as a shared SwiftUI codebase for both iPhone and Apple Watch targets.

- `Shared/` contains reusable models and logic used by both platforms.
- `iOS/` contains phone-specific app state and connectivity code.
- `watchOS/` contains watch-specific app state and sync logic.
- `Tests/` is the project’s test area for validation and regression checks.

## Core data model

The central model is defined in `Shared/PilatesModels.swift`.

- `PilatesClass` represents a full class plan.
- `PilatesClassItem` represents each individual exercise or segment.
- `ClassImportEnvelope` and `ClassImportValidator` handle JSON import and basic validation.

Important implementation details:

- `PilatesClass.totalSeconds` sums the seconds of each item and clamps negative values to zero.
- Empty trimmed strings are normalized away during decoding and object creation.
- `PilatesClassItem.seconds` is clamped to non-negative values to prevent malformed data from producing broken timers.
- The import layer rejects empty classes and invalid JSON with explicit localized errors.

## Shared app logic

`Shared/TimerEngine.swift` and `Shared/RunSessionController.swift` are the main execution/control layers.

- The timer engine should be treated as the source of truth for elapsed time and sequence management.
- Session controllers should keep user-facing flows simple and delegate timing decisions to shared logic instead of duplicating state across platforms.
- Keep model transformations and validation in shared code where possible to avoid platform drift.

## iPhone app structure

`iOS/PilatesTimerApp.swift` is the main app entry for the phone target. The app uses SwiftUI `@StateObject` patterns to preserve state across views.

Relevant code patterns:

- `ClassStore` holds the active workout/class collection and mutation logic.
- `LogStore` manages session history and user logs.
- `PhoneConnectivityManager` is responsible for phone-to-watch synchronization.

Keep the phone side focused on UI orchestration and state propagation; business logic should remain shared when it is platform-neutral.

## Apple Watch app structure

`watchOS/PilatesTimerWatchApp.swift` sets up the watch app and injects environment objects.

- `WatchClassStore` tracks watch-side classes.
- `WatchLogStore` stores watch logs and workout history.
- `WatchConnectivityManager` handles synchronization with the phone app.
- `WorkoutSessionManager` is the watch-specific runtime controller for active sessions.

The watch app is designed to restore key session state from the shared model layer while keeping wearable interactions lightweight.

## Communication and syncing

Cross-device communication is currently modeled around the Apple WatchConnectivity APIs.

- Use serializable shared data models whenever sending state between phone and watch.
- Prefer a single versioned schema for sync payloads to reduce compatibility bugs.
- Keep sync payloads small; avoid sending large UI-only structures when the shared model is enough.

## Coding conventions

- Favor `struct` models with `Codable` conformance for persisted or synced data.
- Keep initialization values defensive and normalize user input early.
- Avoid optional heavy UI logic in shared models; prefer explicit fallback values.
- When adding new fields, update decoding logic and any import validation at the same time.
- Prefer `@StateObject` for long-lived app state and inject dependencies via `.environmentObject(...)` when used by multiple views.

## Testing priorities

As the project grows, the highest-value tests should cover:

- timer accuracy and time clamping
- class import validation
- watch/phone sync payload compatibility
- state restoration for workouts in progress

## Future improvements

Planned follow-up work for the project could include:

- HealthKit or workout lifecycle integration
- real session persistence and export
- richer workout editing screens
- improved notifications and user feedback
- more complete test coverage for cross-platform sync

## Notes for contributors

Before making changes:

1. Check whether the feature belongs in `Shared/` or a platform-specific folder.
2. Reuse existing model conventions rather than introducing parallel types.
3. Validate imported and synced data aggressively to prevent malformed class definitions.
4. Keep app state simple and centralized where possible, especially for timer/session logic.
