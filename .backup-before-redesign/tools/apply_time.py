"""Teach by time: hide reps everywhere, make time the main setting, add a class-length target to the builder."""
import sys, os
root = sys.argv[1]
def edit(path, pairs):
    full = os.path.join(root, path); s = open(full).read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:90], s.count(old))
        s = s.replace(old, new)
    open(full, 'w').write(s)

edit('iOS/ContentView.swift', [
 # ---- class screen move card: no reps
 ('''            if !item.reps.isEmpty {
                Text(item.reps)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brown)
            }
            if !item.setup.isEmpty {''', '''            if !item.setup.isEmpty {'''),
 # ---- phone timer: no reps under the move name
 ('''                        if !item.reps.isEmpty {
                            Text(item.reps).font(.headline).foregroundStyle(Theme.brown)
                        }
''', ''),
 # ---- library list row: time only, as m:ss
 ('''                        if !move.reps.isEmpty {
                            Label(move.reps, systemImage: "repeat")
                                .font(.caption)
                                .foregroundStyle(Theme.brown.opacity(0.6))
                        }
                        if move.seconds > 0 {
                            Label("\\(move.seconds)s", systemImage: "clock")''', '''                        if move.seconds > 0 {
                            Label(TimeFormat.mmss(move.seconds), systemImage: "clock")'''),
 # ---- library detail: drop the reps box
 ('''                        if !move.reps.isEmpty {
                            VStack(spacing: 4) {
                                Label("Reps", systemImage: "repeat")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Theme.gold)
                                Text(move.reps)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.brown)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Theme.gold.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
''', ''),
 # ---- library add/edit form: time stepper instead of reps + seconds text
 ('''                Section("Reps / Repetitions") {
                    TextField("e.g., 5-10x or 100 pumps", text: $reps)
                }
                
                Section("Time") {
                    TextField("Seconds (optional)", text: $seconds)
                        .keyboardType(.numberPad)
                }''', '''                // TO CHANGE: time steps (15 seconds) and longest time (30 min = 1800).
                Section("Time") {
                    Stepper(value: Binding(get: { Int(seconds) ?? 0 }, set: { seconds = "\\($0)" }), in: 0...1800, step: 15) {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(TimeFormat.mmss(Int(seconds) ?? 0))
                                .monospacedDigit()
                                .foregroundStyle(Theme.rose)
                        }
                    }
                }'''),

 # ---- builder: state
 ('''    @State private var loaded = false

    // TO CHANGE: how long a new move runs if the Library doesn't say (in seconds).
    private let defaultSeconds = 60
''', '''    @State private var loaded = false

    // TO CHANGE: starting time for each new move (seconds) and the starting class length (minutes).
    @State private var defaultSeconds = 60
    @State private var targetMinutes = 45
'''),
 ('''    private var totalSeconds: Int { moves.reduce(0) { $0 + $1.item.seconds } }
''', '''    private var totalSeconds: Int { moves.reduce(0) { $0 + $1.item.seconds } }
    private var targetSeconds: Int { targetMinutes * 60 }
    /// e.g. "13:00 left to fill" or "2:30 over".
    private var fitText: String {
        let gap = targetSeconds - totalSeconds
        if gap == 0 { return "Exactly \\(targetMinutes) min" }
        return gap > 0 ? "\\(TimeFormat.mmss(gap)) left to fill" : "\\(TimeFormat.mmss(-gap)) over"
    }
'''),
 # ---- builder: class section gets class length + fit tools
 ('''                    TextField("Props to bring (comma separated)", text: $extraProps)
                    HStack {
                        Chip(text: "\\(moves.count) moves")
                        Chip(text: TimeFormat.mmss(totalSeconds) + " total", tint: Theme.gold)
                    }
                    .listRowSeparator(.hidden)
                }''', '''                    TextField("Props to bring (comma separated)", text: $extraProps)
                }

                // --- Time: how long the class is and how the moves fill it
                Section {
                    Stepper(value: $targetMinutes, in: 5...120, step: 5) {
                        HStack {
                            Text("Class length")
                            Spacer()
                            Text("\\(targetMinutes) min").foregroundStyle(Theme.rose).monospacedDigit()
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\\(TimeFormat.mmss(totalSeconds)) planned")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Theme.berry)
                            Spacer()
                            Text(fitText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(totalSeconds > targetSeconds ? Theme.clay : Theme.sage)
                        }
                        ProgressView(value: Double(min(totalSeconds, targetSeconds)), total: Double(max(targetSeconds, 1)))
                            .tint(totalSeconds > targetSeconds ? Theme.clay : Theme.rose)
                    }
                    if !moves.isEmpty {
                        Button {
                            spreadEvenly()
                        } label: {
                            Label("Spread \\(targetMinutes) min evenly across \\(moves.count) moves", systemImage: "equal.circle")
                        }
                        .foregroundStyle(Theme.rose)
                    }
                } header: {
                    Text("Time")
                } footer: {
                    Text("Every move runs on time. Change one move's time by tapping it.")
                }'''),
 ('''                    Text("Tap a move to change its time, reps or cues. Swipe left to delete. Tap Reorder to drag moves.")''',
  '''                    Text("Tap a move to change its time or cues. Swipe left to delete. Tap Reorder to drag moves.")'''),
 # ---- builder: time for new moves
 ('''                    TextField("Section for new moves (e.g. Warm-Up)", text: $sectionForNewMoves)
''', '''                    TextField("Section for new moves (e.g. Warm-Up)", text: $sectionForNewMoves)
                    Stepper(value: $defaultSeconds, in: 15...600, step: 15) {
                        HStack {
                            Text("Time for each new move").foregroundStyle(Theme.brown)
                            Spacer()
                            Text(TimeFormat.mmss(defaultSeconds)).monospacedDigit()
                        }
                    }
                    if !moves.isEmpty {
                        Button("Set every move to \\(TimeFormat.mmss(defaultSeconds))") {
                            for i in moves.indices { moves[i].item.seconds = defaultSeconds }
                        }
                    }
'''),
 # ---- builder: library moves use your time, not the library's reps/time
 ('''                            reps: libraryMove.reps,
                            seconds: libraryMove.seconds > 0 ? libraryMove.seconds : defaultSeconds,''',
  '''                            seconds: defaultSeconds,'''),
 # ---- builder: starting class length
 ('''        case .blank:
            break
        case .levelI:
            name = "Level I Mat"
            moves = LevelIMatTemplate.exercises.map { DraftMove(item: $0) }
        case .edit(let plan):
            name = plan.name''', '''        case .blank:
            break
        case .levelI:
            name = "Level I Mat"
            moves = LevelIMatTemplate.exercises.map { DraftMove(item: $0) }
        case .edit(let plan):
            name = plan.name
            targetMinutes = max(5, Int((Double(plan.totalSeconds) / 60 / 5).rounded()) * 5)'''),
 ('''    // WHAT: saves the class (keeping the same class when editing) and closes the builder.''',
  '''    // WHAT: gives every move the same time so the class adds up to the class length (rounded to 5 seconds).
    private func spreadEvenly() {
        guard !moves.isEmpty else { return }
        let each = max(15, Int((Double(targetSeconds) / Double(moves.count) / 5).rounded()) * 5)
        for i in moves.indices { moves[i].item.seconds = each }
    }

    // WHAT: saves the class (keeping the same class when editing) and closes the builder.'''),
 # ---- builder row: time only, shown big on the right
 ('''                    Text([TimeFormat.mmss(item.seconds), item.reps].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.brown.opacity(0.7))
                }
                Spacer()''', '''                    if !item.cue.isEmpty {
                        Text(item.cue)
                            .font(.caption)
                            .foregroundStyle(Theme.brown.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(TimeFormat.mmss(item.seconds))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.rose)'''),
 # ---- move editor: quick time buttons, no reps
 ('''                    TextField("Reps (e.g. 6–8, 10 breaths)", text: $move.item.reps)
                }''', '''                    // TO CHANGE: the quick time buttons (in seconds).
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([30, 45, 60, 90, 120, 180, 300], id: \\.self) { secs in
                                Button(TimeFormat.mmss(secs)) { move.item.seconds = secs }
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(move.item.seconds == secs ? Theme.rose : Theme.blush, in: Capsule())
                                    .foregroundStyle(move.item.seconds == secs ? .white : Theme.berry)
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }'''),
])

# ---- watch timer: no reps under the countdown
edit('watchOS/WatchContentView.swift', [
 ('''                            if !item.reps.isEmpty {
                                Text(item.reps)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.petal)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
''', ''),
])
print('time-based applied')
