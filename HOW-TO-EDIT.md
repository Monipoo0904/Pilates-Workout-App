# How to edit Pilates Timer yourself

A plain-language guide for Monique. It covers where things live, how to make the common changes, and what to do when Xcode shows red errors.

---

## 1. Golden rules (read these first)

1. **Save a checkpoint before every change.** In Xcode: **Integrate → Commit…** (or **Source Control → Commit**), type a short note like "before changing colors", and click **Commit**. If you break something, you can go back.
2. **Change one thing, then build.** Press **⌘B** after each small edit. Fixing one error is easy; fixing twenty at once is not.
3. **Order of moves = order you teach.** A class runs top to bottom, exactly as written. Never ask Xcode (or an AI assistant) to "sort" or "organize" the moves in a class.
4. **Built-in class changed? Raise its `version`.** Phones and watches keep their own saved copy, and they only take your edit when the number goes up (3 → 4).
5. **Shared files go to both apps.** Anything in the **Shared** folder must be checked for both **PilatesTimerProject** and **PilatesTimerWatchApp** under **Target Membership** (right sidebar).
6. **Don't change the bundle identifiers.** They're set and working:
   - iPhone: `com.myvillageprojecttechnologiescorp.pilatestimer`
   - Watch: `com.myvillageprojecttechnologiescorp.pilatestimer.watchkitapp`

---

## 2. What's where

| Folder / file | What it holds |
|---|---|
| `iOS/ContentView.swift` | Every iPhone screen: Classes, Hours, Students, Library, the class builders, and the run (timer) screen. Use **⌘F** to jump around. |
| `iOS/ClassStore.swift` | Saving classes, students, course modules and library moves on the phone. |
| `iOS/LogStore.swift` | Saving your logged hours. |
| `iOS/PhoneConnectivityManager.swift` | Talking to the watch (sending classes, starting the watch when a class starts). |
| `watchOS/WatchContentView.swift` | The watch screens: class list and run screen (ring, haptics, 10-minutes-left alert). |
| `watchOS/WorkoutSessionManager.swift` | The Apple Workout that runs on the watch during class. |
| `Shared/SampleData.swift` | **Built-in classes** (Fall Into Pilates, Beginner Script, Glute & Core…). |
| `Shared/LogModels.swift` | **Colors and fonts (Theme)**, hour log format, students, course modules, and the **exercise library** (all styles). |
| `Shared/PilatesModels.swift` | What a class and a move are made of (name, reps, seconds, cue, Building Block…). |
| `Shared/TimerEngine.swift` | The timer itself. Rarely needs changes. |
| `PilatesTimerProject/Assets.xcassets` | iPhone app icon and accent color. |
| `PilatesTimerWatchApp Watch App/Assets.xcassets` | Watch app icon and accent color. |

Tip: press **⇧⌘O** (Open Quickly) and type a file or word, like `SampleData`, to jump straight to it.

---

## 3. Everyday edits

### Build a class on your iPhone (no code)
Classes tab → **New class** (blank) or **Level I** (starts with the classical order). Add moves from the Library or write your own, tap a move to set its time/reps/cues, tap **Reorder** to drag. **Save** sends it to your watch automatically. To change it later: open the class → pencil (or **⋯** for Duplicate / Delete).

### Change a built-in class's moves, cues or times in code
1. Open `Shared/SampleData.swift`.
2. Find the class (⌘F, type its name, e.g. `fallIntoPilates`).
3. Each move is one line that starts with `PilatesClassItem(`. Edit the text inside the quotes:
   - `section:` heading shown above the move ("Mat flow")
   - `name:` move name
   - `reps:` what you say ("6–8", "10 breaths")
   - `seconds:` how long the timer runs for this move
   - `cue:`, `buildingBlock:`, `modification:`, `transition:` the coaching notes
4. **To add a move:** copy a whole line, paste it where it should happen in class, and edit it. Every line except the last needs a comma at the end.
5. **To reorder:** move the whole line up or down. Top runs first.
6. Raise the class's `version:` number by 1.
7. Press **⌘B**, then **⌘R**.

> Quotes inside a cue need a backslash: `cue: "Say \"inhale\" and lift."`

### Add a new class without code
In the iPhone app, use **Paste** or **Import** on the Classes tab with this format:

```json
{
  "version": 1,
  "id": "my-new-class",
  "name": "Sunday Flow (30 min)",
  "props": ["Mat", "Pilates ball"],
  "items": [
    { "section": "Warm-up", "name": "Breathing", "reps": "5 breaths", "seconds": 60,
      "cue": "Inhale wide into the ribs.", "buildingBlock": "", "modification": "", "transition": "", "props": [] }
  ]
}
```
Then tap **Send to Watch**.

### Add moves to the exercise library
- **In the app:** Library tab → **+**. Fastest way.
- **In code (so it ships with the app):** open `Shared/LogModels.swift`, find `moreStyles`, copy a `LibraryMove(` line and edit it. Pick a `style:` (`.classical`, `.contemporary`, `.props`, `.barre`, `.sculpt`, `.mobility`, `.prenatal`, `.standing`) and an `area:` (`.warmup`, `.arms`, `.glutes`, `.core`, `.stretch`). Leave out the `id:` part if you like; names must be unique.

### Change your hour goals or deadline
`iOS/ContentView.swift` → ⌘F `practiceGoal`. Edit the numbers or the `DateComponents(year: 2026, month: 11, day: 13)` line.

### Change colors or fonts
`Shared/LogModels.swift` → ⌘F `enum Theme`. Each color is a hex code, like `Color(hex: 0xD1457A)` for rose. Change the 6 characters after `0x`. Headings use `Theme.display(size)` (serif italic).

### Change the course module names
`Shared/LogModels.swift` → ⌘F `CourseModuleSet`. (Your real Peak sections are already there.)

### Change the app icon
1. Make a **1024 × 1024 PNG** with no transparency and square corners (iPhone rounds them).
2. In Xcode open `PilatesTimerProject/Assets.xcassets` → **AppIcon** and drag your PNG onto the box.
3. Do the same in `PilatesTimerWatchApp Watch App/Assets.xcassets` → **AppIcon**.
4. Delete the app from the simulator/phone and run again (icons are cached).

### Change the name under the icon
Click the blue project → TARGETS → each target → **Build Settings** → search **Display Name** → edit "Pilates Timer".

---

## 4. Build and run

| What | How |
|---|---|
| Run on iPhone simulator | Scheme **PilatesTimerProject** + **iPhone 17** → **⌘R** |
| Run on watch simulator | Scheme **PilatesTimerWatchApp Watch App** + an **Apple Watch** → **⌘R** |
| Fresh start when things act weird | **Product → Clean Build Folder** (⇧⌘K), delete the app from the simulator, ⌘R |
| Reset a simulator completely | Simulator menu **Device → Erase All Content and Settings** |
| Your real iPhone + Watch | Plug the iPhone in, pick it as the destination, ⌘R. The watch app installs with it (watch must be paired, unlocked and nearby). |

Phone→watch auto-start and HealthKit only fully work on real devices.

---

## 5. When Xcode shows red errors

Click the red number at the top (or press **⌘5**) to see the list. Fixes for the ones we've already hit:

| Error says… | Fix |
|---|---|
| *does not conform to protocol 'ObservableObject'* / *init(wrappedValue:) not available… 'Combine'* | Add `import Combine` under `import Foundation` in that file. |
| *Cannot find 'Something' in scope* | That file isn't in the right target. Select it → right sidebar → **Target Membership** → check the target that needs it (Shared files: both). |
| *Unable to resolve module dependency: 'UIKit'* (on watch) or *'WatchKit'* (on iPhone) | An iPhone file is in the watch target, or the reverse. Fix its Target Membership. |
| *'main' attribute can only apply to one type* | Two app start files in one target. Only `PilatesTimerApp` (iPhone) and `PilatesTimerWatchApp` (watch) should have `@main`. |
| *bundle identifier does not start with its parent app's…* / *WKCompanionAppBundleIdentifier* | Check the two IDs in rule 6. No spaces or dashes before `com.` Watch target → Build Settings → search **companion** → must equal the iPhone ID. |
| *No profiles for… / Communication with Apple failed* (yellow) | Signing & Capabilities → Team = MyVillage Project Technologies CORP., Automatically manage signing on. Plug in your iPhone once. |
| Class runs in a strange order | Something is sorting the moves. Search for `.sorted` near `items` and remove it. See rule 3. |

Still stuck? Copy the full error (right-click → Copy) and paste it to Claude.

---

## 6. Using an AI assistant in Xcode safely

Before each request, **commit** (rule 1). Paste these house rules at the start of your request:

```text
House rules for this project:
- Keep the order of moves in every class exactly as written; never sort PilatesClass.items or orderedItems.
- When changing a built-in class in Shared/SampleData.swift, increase its version number.
- Files in Shared/ must belong to BOTH targets (iPhone and watch). Tell me which target each new file needs.
- Don't change bundle identifiers, signing, or WKCompanionAppBundleIdentifier.
- Keep "import Combine" in every file with an ObservableObject.
- Keep the Theme colors/fonts in Shared/LogModels.swift for any new screen.
- Change as little as needed, build after each step, and list every file you changed.
```

After it finishes: open the **Source Control navigator** (⌘2) → look at **Changes** to see exactly what it edited, then build and test before committing.

---

## 7. Undo

- **Undo the last edits in one file:** ⌘Z, or right-click the file → **Source Control → Discard Changes**.
- **Go back to a checkpoint:** Source Control navigator (⌘2) → **Repositories** → right-click a commit → **Check Out** (ask Claude before doing this if unsure).
- **Backups from Claude's changes:** the hidden folder `.backup-before-redesign` in the project folder (press **⇧⌘.** in Finder to show hidden files).
