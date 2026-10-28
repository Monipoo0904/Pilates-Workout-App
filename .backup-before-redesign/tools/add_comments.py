"""Adds plain-English WHAT / TO CHANGE comments to the Pilates Timer project.
Comments only: no code is changed. Safe to run twice (skips what's already there)."""
import re, sys, os

root = sys.argv[1]
BAR = '// ' + '=' * 70

# ---------------------------------------------------------------- file headers
HEADERS = {
 'iOS/PilatesTimerApp.swift': ('iPhone app', 'Starts the iPhone app and shows ContentView (the tab bar).',
    'Rarely needed. Screens live in ContentView.swift.'),
 'iOS/ContentView.swift': ('iPhone app', 'Every iPhone screen: the tab bar, Classes (list, detail, builders, edit), the class timer (run screen), Hours (progress, log, weekly plan), Library, and Students.',
    'Use Cmd+F to jump to a screen name below (e.g. "struct HoursView"). Each screen has a WHAT / TO CHANGE note above it.'),
 'iOS/ClassStore.swift': ('iPhone app', 'Saves and loads your data on the iPhone: classes, students, course modules, and library moves (each in its own JSON file).',
    'Built-in content is in Shared/SampleData.swift and Shared/LogModels.swift; edit it there, not here.'),
 'iOS/LogStore.swift': ('iPhone app', 'Saves and loads your logged hours (practice / observation / teaching) and exports them as CSV.',
    'Change the CSV columns in exportCSV().'),
 'iOS/PhoneConnectivityManager.swift': ('iPhone app', 'Talks to the Apple Watch: sends your classes, opens the watch app when a class starts, and receives watch logs.',
    'Change the status messages shown on the phone here.'),
 'watchOS/PilatesTimerWatchApp.swift': ('Apple Watch app', 'Starts the watch app, shares the class/log/connection data with every watch screen, and lets the iPhone launch it for a workout.',
    'Rarely needed.'),
 'watchOS/WatchContentView.swift': ('Apple Watch app', 'Watch screens: the class list, the run screen (timer ring, controls, cues, haptics, 10-minutes-left alert), and the hours glance.',
    'Haptics: handleHaptics(). 10-minute alert: announceTenMinutes(). Colors come from Theme in Shared/LogModels.swift.'),
 'watchOS/WatchClassStore.swift': ('Apple Watch app', 'Saves the classes on the watch and replaces them when the iPhone sends new ones.',
    'Rarely needed.'),
 'watchOS/WatchConnectivityManager.swift': ('Apple Watch app', 'Receives classes and "start this class" messages from the iPhone, and sends watch logs back.',
    'How old a start request can be before it is ignored: see the TO CHANGE note in handleCommand().'),
 'watchOS/WatchLogStore.swift': ('Apple Watch app', 'Saves classes you log on the watch until they sync to the iPhone.',
    'Rarely needed.'),
 'watchOS/WorkoutSessionManager.swift': ('Apple Watch app', 'Runs an Apple "Pilates" workout during class (heart rate, rings, Fitness app).',
    'Indoor/outdoor: change config.locationType in startPilatesWorkout().'),
 'Shared/LogModels.swift': ('Shared by iPhone + Watch', 'The look of the app (Theme colors and fonts), small reusable pieces (Chip, TimerRing, LabeledNote), the 10-minute alert, hour logs, students, course modules, the exercise library (all styles), and your web tracker data.',
    'Colors: enum Theme. Alert time: ClassAlerts. Course names: CourseModuleSet. New library moves: moreStyles.'),
 'Shared/PilatesModels.swift': ('Shared by iPhone + Watch', 'What a class and a move are made of (name, reps, seconds, cue, Building Block, Modification, transition, props), JSON import, and the Level I mat template.',
    'Add a new field to every move: PilatesClassItem. Level I exercise list: LevelIMatTemplate.'),
 'Shared/SampleData.swift': ('Shared by iPhone + Watch', 'The built-in classes that come with the app (Fall Into Pilates, Beginner Script, Glute & Core...).',
    'Edit moves line by line; top runs first. After any change, raise that class\'s version: number so phones and watches update.'),
 'Shared/TimerEngine.swift': ('Shared by iPhone + Watch', 'The class clock: works out which move you are on, time left in the move and in the class, pause/resume, next/back.',
    'Rarely needed. It always follows the order of moves in the class.'),
 'Shared/RunSessionController.swift': ('Shared by iPhone + Watch', 'Connects the timer to the screens: refreshes 4 times a second and tells the screen the current and next move.',
    'Rarely needed.'),
}

# ------------------------------------------------- notes above types (name -> (what, change))
TYPES = {
 # iOS/ContentView.swift
 'ContentView': ('The iPhone tab bar (Classes, Hours, Students, Library) and the shared data every tab uses.', 'Tab names, icons or order: edit the .tabItem lines below.'),
 'ClassListView': ('Classes tab home screen: title, Paste / Import / Send to Watch buttons, and your class cards.', 'Header text: the Text("Pilates Timer") lines. Buttons: the ActionTile lines.'),
 'ActionTile': ('One square button on the Classes screen (icon + label).', 'Size/colors: the padding and Theme values below.'),
 'ClassCard': ('One class card in the list: name, minutes, number of moves, props.', 'What the card shows: edit the Chip / Text lines.'),
 'WorkoutBuilderView': ('Quick workout builder: name a workout, add moves one at a time (series, reps, seconds, cues) and save it as a class.', 'Default reps/seconds: the @State values at the top.'),
 'ClassDetailView': ('One class: name, minutes, props, the Start class button, and every move card in teaching order.', 'Button text: "Start class". Note under it: the Text below the button.'),
 'ClassEditFormView': ('Edit an existing class: name, props, and its moves.', 'Prop choices: commonProps.'),
 'MoveCard': ('One move on the class screen: name, time, reps, cue, Building Block, Modification, Transition, props.', 'Label names/colors: the LabeledNote lines.'),
 'PhoneRunView': ('The iPhone class timer: big ring for the current move, whole-class progress, next move, controls, 10-minutes-left banner, and the "Log this class?" prompt at the end.', 'Ring size: .frame(width: 240...). Banner text: "10 minutes left". Log choices: the Button lines in .alert.'),
 'RoundControl': ('The round back / play-pause / next buttons on the timer.', 'Sizes are set where it is used (size: 58 / 78).'),
 'HoursView': ('Hours tab: progress toward 20 / 10 / 20 hours, the session log, and the weekly plan.', 'Goals and deadline: practiceGoal ... deadline just below.'),
 'ProgressCard': ('One progress card on the Hours tab.', 'Look of the card: padding/colors below.'),
 'SessionLogCell': ('One logged session in the Hours list.', 'What it shows: the Text lines below.'),
 'WeeklyPlanView': ('Weekly plan page: weekly targets and your plan notes.', 'Default plan text: the planNotes value.'),
 'LogSessionForm': ('Form to log or edit a session: date, type, hours, class, place, students, note.', 'Default hours: hours = 0.5.'),
 'LevelIMatBuilderView': ('Level I mat class builder: pick which classical exercises to include (order stays classical), props, and an ending.', 'Ending choices: endings. Prop choices: commonProps. Exercises: LevelIMatTemplate in Shared/PilatesModels.swift.'),
 'CustomClassBuilderView': ('Custom class builder: add moves from the Library, add section headings, set reps/seconds, reorder by dragging.', 'Prop choices: commonProps.'),
 'MoveSelectorView': ('Pop-up list for picking Library moves to add to a custom class.', 'Search/filter options below.'),
 'AddSectionView': ('Pop-up for adding a section heading (e.g. Warm-Up) to a custom class.', 'Example text: the TextField placeholder.'),
 'LibraryView': ('Library tab: search moves and filter by Style, Area and Props.', 'Add filter options: copy one of the chip rows. Styles: MoveStyle in Shared/LogModels.swift.'),
 'MoveRowView': ('One move in the Library list.', 'What it shows: the Text lines below.'),
 'MoveDetailView': ('Full details for one Library move, with an Edit button.', None),
 'MoveFormView': ('Form to add or edit a Library move.', 'Prop choices: the props list near the top.'),
 'StudentsView': ('Students tab: list of students and the add button.', None),
 'StudentRowView': ('One student in the list.', None),
 'StudentDetailView': ('One student: their info, teaching sessions with them, and total hours together.', None),
 'StudentFormView': ('Form to add or edit a student (name, contact, injuries, goals, notes).', None),
 'ShareSheet': ('The iPhone share sheet used for CSV export.', None),
 # stores
 'ClassStore': ('Your classes on the iPhone. Loads them, adds built-in classes you don\'t have, saves imports and edits.', 'Built-in classes live in Shared/SampleData.swift.'),
 'StudentStore': ('Your students on the iPhone (saved in students.json).', None),
 'CourseStore': ('Your course modules and progress (saved in course.json).', 'Module names: CourseModuleSet in Shared/LogModels.swift.'),
 'LibraryStore': ('Your exercise library (saved in library.json). Adds built-in moves you don\'t have and removes duplicate copies.', 'Built-in moves: LibraryMoveSet in Shared/LogModels.swift.'),
 'LogStore': ('Your logged hours on the iPhone (saved in logs.json).', None),
 'PhoneConnectivityManager': ('iPhone side of the iPhone <-> Watch connection.', None),
 # watch
 'WatchAppDelegate': ('Lets the iPhone open this watch app with a Pilates workout.', None),
 'PilatesTimerWatchApp': ('Starts the watch app and shares data with all watch screens.', None),
 'PilatesTimerApp': ('Starts the iPhone app.', None),
 'RunTarget': ('Which class to open on the watch (tapped, or sent from the iPhone).', None),
 'WatchContentView': ('Watch home: app title, sync status, and your class list. Opens a class automatically when the iPhone starts one.', 'Row text: the Text lines inside NavigationLink.'),
 'WatchRunView': ('Watch class timer: section, move name, ring with time left, class time left, next move, controls, cues, End Class, and the log prompt.', 'Ring size: .frame(width: 118...). Haptics: handleHaptics(). 10-minute alert: announceTenMinutes().'),
 'WatchHoursGlanceView': ('Watch hours glance: today\'s hours and hours left per type.', 'Goals here must match the iPhone goals in HoursView.'),
 'WatchClassStore': ('Your classes on the watch.', None),
 'StartRequest': ('A class the iPhone asked the watch to start.', None),
 'WatchConnectivityManager': ('Watch side of the iPhone <-> Watch connection.', None),
 'WatchLogStore': ('Logs made on the watch, kept until they sync to the iPhone.', None),
 'WorkoutSessionManager': ('Starts and ends the Apple Pilates workout on the watch.', None),
 # shared
 'LogType': ('The three kinds of hours: teaching, practice, observation.', None),
 'ClassLogEntry': ('One logged session: date, type, hours, class, where it came from, place, students, note.', 'New fields must be optional (?) so older saved logs still load.'),
 'TimeFormat': ('Turns seconds into "m:ss" and rounds hours to quarter hours.', None),
 'Theme': ('The app\'s colors and heading font, matched to the Fall Into Pilates flyer and MyVillage colors.', 'Change a color by editing its 6-character hex code after 0x.'),
 'Chip': ('Small rounded label (e.g. "45 min", "Pilates ball").', None),
 'TimerRing': ('The circular progress ring used by the timers and hour goals.', None),
 'LabeledNote': ('Icon + title + text block used for Cue, Building Block, Modification and Transition.', None),
 'ClassAlerts': ('When the "10 minutes left" alert fires.', 'Change tenMinutes (in seconds): 600 = 10 min, 300 = 5 min.'),
 'Student': ('One student: name, contact, injuries, goals, notes.', None),
 'CourseModule': ('One course section with done / date / notes.', None),
 'CourseModuleSet': ('The Peak Pilates Level I course sections shown on a new install.', 'Edit titles here.'),
 'ExerciseArea': ('Body areas used to filter the Library.', 'Add an area: add a case AND its label below.'),
 'LibraryMove': ('One move in the exercise library.', None),
 'LibraryMoveSet': ('Built-in library moves.', 'Add moves to moreStyles (copy a line, edit it). Names must be unique.'),
 'WebTrackerImport': ('Your data from the web tracker, added once on first launch (hours, students, course progress).', None),
 'MoveStyle': ('Teaching styles used to filter the Library (Classical, Contemporary, Props, Barre...).', 'Add a style: add a case AND its label below.'),
 'WorkoutSeries': ('Groups moves into Lunge / Squat / Arms / Abs for the workout builder.', 'Which words put a move in a group: infer(from:) below.'),
 'PilatesClass': ('A whole class: name, props, and its moves in teaching order.', 'Never sort items: the order here is the order you teach.'),
 'PilatesClassItem': ('One move in a class: section, name, reps, seconds, setup, cue, Building Block, Modification, transition, props.', None),
 'ClassImportEnvelope': ('The JSON shape used by Paste / Import.', None),
 'ClassImportError': ('Error messages shown when an import fails.', 'Edit the message text below.'),
 'ClassImportValidator': ('Checks pasted/imported JSON before adding a class.', None),
 'LevelIMatTemplate': ('The classical Level I mat exercises used by the Level I builder, in classical order.', 'Keep them in classical order.'),
 'SampleData': ('Built-in classes.', 'Raise a class\'s version number whenever you change it.'),
 'TimerSnapshot': ('Everything the screens need to know about the timer right now.', None),
 'TimerEngine': ('The class clock.', None),
 'RunSessionController': ('Runs the timer for a screen and tells it the current and next move.', None),
}

# ------------------------------------------- notes above specific lines (file, anchor, lines)
ANCHORS = [
 ('iOS/ContentView.swift', '    private let practiceGoal: Double = 20.0', ['TO CHANGE: your hour goals and deadline. Also update WatchHoursGlanceView in watchOS/WatchContentView.swift.']),
 ('iOS/ContentView.swift', '    private let endings = [', ['TO CHANGE: the ending choices in the Level I builder.']),
 ('iOS/ContentView.swift', '    private let commonProps = ["Resistance Band"', ['TO CHANGE: prop choices in this builder. (Library moves use "Stretch band", "Yoga block", "Pilates ball"; match the spelling if you want filters to line up.)']),
 ('iOS/ContentView.swift', '    private func announceTenMinutes() {', ['WHAT: vibrates the phone and shows the "10 minutes left" banner for 6 seconds.', 'TO CHANGE: the banner text is in .overlay above; the timing is ClassAlerts in Shared/LogModels.swift.']),
 ('iOS/ContentView.swift', '            connectivity.startClassOnWatch(controller.plan)', ['WHAT: starting a class on the iPhone also starts it on the Apple Watch.']),
 ('watchOS/WatchContentView.swift', '    private func handleHaptics(', ['WHAT: wrist taps during class: a "start" tap on every new move, a click at 10 seconds left, and 3 taps for the last 3 seconds.', 'TO CHANGE: the numbers 10 and 1...3, or the tap types (.start, .click, .notification, .success).']),
 ('watchOS/WatchContentView.swift', '    private func announceTenMinutes() {', ['WHAT: two wrist taps and a gold "10 min left" badge for 6 seconds.']),
 ('watchOS/WatchContentView.swift', '    private func openRequestedClass() {', ['WHAT: when the iPhone starts a class, jump straight into it on the watch.']),
 ('watchOS/WatchContentView.swift', '    private let practiceGoal = 20.0', ['TO CHANGE: keep these goals the same as HoursView on the iPhone.']),
 ('watchOS/WatchConnectivityManager.swift', '        guard Date().timeIntervalSince1970 - sentAt < 2 * 60 * 60,', ['TO CHANGE: ignore start requests older than 2 hours (2 * 60 * 60 seconds).']),
 ('watchOS/WorkoutSessionManager.swift', '        config.locationType = .indoor', ['TO CHANGE: .indoor or .outdoor (outdoor classes can use .outdoor).']),
 ('iOS/PhoneConnectivityManager.swift', '    func sendClasses(', ['WHAT: sends all your classes to the watch (the "Send to Watch" button).']),
 ('Shared/LogModels.swift', '    static let blush = Color(hex: 0xFBE4EA)', ['TO CHANGE: colors. blush/cream = backgrounds, rose = buttons and rings, berry = headings, gold = accents, sage = Building Blocks, clay = Modifications.']),
 ('Shared/LogModels.swift', '    static func display(_ size: CGFloat) -> Font {', ['TO CHANGE: heading font. .serif can be .default or .rounded; remove .italic() for upright.']),
 ('Shared/LogModels.swift', '    static let tenMinutes = 600', ['TO CHANGE: alert time in seconds.']),
 ('Shared/LogModels.swift', '    static let moreStyles: [LibraryMove] = [', ['TO CHANGE: add a move by copying one line and editing it. Each line: name, area, props, reps, seconds, cue, buildingBlock, modification, style.']),
 ('Shared/SampleData.swift', '    static let builtIns: [PilatesClass] = [', ['TO CHANGE: which built-in classes appear, and in what order in the list.']),
 ('Shared/PilatesModels.swift', '    static func infer(from name: String', ['TO CHANGE: the words that put a move in Lunge / Squat / Arms / Abs.']),
 ('Shared/RunSessionController.swift', '        ticker = Timer.publish(every: 0.25', ['WHAT: refresh the timer 4 times a second.']),
]

DECL = re.compile(r'^(\s*)(?:@\w+\s+)*(?:public |private |fileprivate |final )*(struct|class|enum|extension) (\w+)')

def already(lines, i):
    return i > 0 and ('WHAT:' in lines[i - 1] or 'TO CHANGE:' in lines[i - 1])

def note_lines(indent, what, change):
    out = []
    if what: out.append(f'{indent}// WHAT: {what}\n')
    if change: out.append(f'{indent}// TO CHANGE: {change}\n')
    return out

total = 0
for path in sorted(set(HEADERS) | {a[0] for a in ANCHORS}):
    full = os.path.join(root, path)
    if not os.path.exists(full):
        continue
    lines = open(full).read().splitlines(keepends=True)
    out, seen = [], set()
    for i, line in enumerate(lines):
        m = DECL.match(line)
        if m and m.group(2) != 'extension' and m.group(3) in TYPES and m.group(3) not in seen:
            seen.add(m.group(3))
            # put the note above attribute lines like @MainActor
            k = len(out)
            while k > 0 and out[k - 1].strip().startswith('@'):
                k -= 1
            if not (k > 0 and ('WHAT:' in out[k - 1] or 'TO CHANGE:' in out[k - 1])):
                what, change = TYPES[m.group(3)]
                out[k:k] = note_lines(m.group(1), what, change); total += 1
        for f, anchor, notes in ANCHORS:
            if f == path and line.rstrip('\n').startswith(anchor) and not already(out + [line], len(out)):
                indent = re.match(r'\s*', line).group(0)
                out += [f'{indent}// {n}\n' for n in notes]; total += 1
        out.append(line)
    text = ''.join(out)
    if path in HEADERS and 'WHAT THIS FILE DOES' not in text:
        where, what, change = HEADERS[path]
        head = (f'{BAR}\n// {os.path.basename(path)}  ({where})\n// WHAT THIS FILE DOES: {what}\n'
                f'// TO CHANGE: {change}\n// Step-by-step help: HOW-TO-EDIT.md in the project folder.\n{BAR}\n\n')
        text = head + text; total += 1
    open(full, 'w').write(text)
print('comments added:', total)
