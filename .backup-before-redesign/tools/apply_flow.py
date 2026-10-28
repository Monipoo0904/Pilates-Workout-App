"""Class flow: series grouped in class order (stretch first and last), one-sided moves right then left, layer-up options."""
import sys, os, subprocess
root = sys.argv[1]; tools = os.path.dirname(os.path.abspath(__file__))
def edit(path, pairs):
    full = os.path.join(root, path); s = open(full).read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:90], s.count(old))
        s = s.replace(old, new)
    open(full, 'w').write(s)

# ---------------- Shared models: layers field
edit('Shared/PilatesModels.swift', [
 ('''    var transition: String
    var props: [String]
    var series: WorkoutSeries
''', '''    var transition: String
    /// Harder options for this move ("layer up"). Empty = use the built-in list (MoveLayers).
    var layers: String
    var props: [String]
    var series: WorkoutSeries
'''),
 ('''        transition: String = "",
        props: [String] = [],
        series: WorkoutSeries? = nil
    ) {''', '''        transition: String = "",
        layers: String = "",
        props: [String] = [],
        series: WorkoutSeries? = nil
    ) {'''),
 ('''        self.transition = transition
        self.props = props.compactMap''', '''        self.transition = transition
        self.layers = layers
        self.props = props.compactMap'''),
 ('''        transition = (try c.decodeIfPresent(String.self, forKey: .transition))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
''', '''        transition = (try c.decodeIfPresent(String.self, forKey: .transition))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        layers = (try c.decodeIfPresent(String.self, forKey: .layers))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
'''),
])
edit('Shared/LogModels.swift', [
 ('''    /// Classical, contemporary, barre... nil for moves you add yourself.
    var style: MoveStyle?

    init(id: UUID = UUID(), name: String, area: ExerciseArea, props: [String] = [], reps: String = "", seconds: Int = 0, cue: String, buildingBlock: String, modification: String, style: MoveStyle? = nil) {''',
  '''    /// Classical, contemporary, barre... nil for moves you add yourself.
    var style: MoveStyle?
    /// Harder "layer up" options you wrote. nil = use the built-in list (MoveLayers).
    var layers: String?

    init(id: UUID = UUID(), name: String, area: ExerciseArea, props: [String] = [], reps: String = "", seconds: Int = 0, cue: String, buildingBlock: String, modification: String, style: MoveStyle? = nil, layers: String? = nil) {'''),
 ('''        self.modification = modification
        self.style = style
    }''', '''        self.modification = modification
        self.style = style
        self.layers = layers
    }'''),
])
gen = subprocess.run([sys.executable, os.path.join(tools, 'gen_layers.py'), '/dev/stdout'], capture_output=True, text=True).stdout
gen = gen[:gen.rindex('\n', 0, len(gen) - 1)] + '\n' if gen.strip().endswith('layer entries') else gen
with open(os.path.join(root, 'Shared/LogModels.swift'), 'a') as f:
    f.write(gen)

# ---------------- Show layers: phone class screen and watch
edit('iOS/ContentView.swift', [
 ('''                LabeledNote(title: "Modification", text: item.modification, icon: "exclamationmark.triangle.fill", color: Theme.clay)
            }''', '''                LabeledNote(title: "Modification", text: item.modification, icon: "exclamationmark.triangle.fill", color: Theme.clay)
            }
            if !item.displayLayers.isEmpty {
                LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.berry)
            }'''),
])
edit('watchOS/WatchContentView.swift', [
 ('''                            LabeledNote(title: "Modification", text: item.modification, icon: "exclamationmark.triangle.fill", color: Theme.peach, textColor: .white)
                        }''', '''                            LabeledNote(title: "Modification", text: item.modification, icon: "exclamationmark.triangle.fill", color: Theme.peach, textColor: .white)
                        }
                        if !item.displayLayers.isEmpty {
                            LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.rose, textColor: .white)
                        }'''),
])

# ---------------- Library: show + edit layers
edit('iOS/ContentView.swift', [
 ('''                // Modification
                VStack(alignment: .leading, spacing: 8) {
                    Label("Modification", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    Text(move.modification)
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
''', '''                // Modification
                VStack(alignment: .leading, spacing: 8) {
                    Label("Modification", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.berry)
                    Text(move.modification)
                        .font(.subheadline)
                        .foregroundStyle(Theme.brown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)

                // Layer up (harder options)
                if !move.displayLayers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Layer up", systemImage: "plus.square.on.square")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.berry)
                        Text(move.displayLayers)
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
'''),
 ('''    @State private var modification = ""
    ''', '''    @State private var modification = ""
    @State private var layers = ""
    '''),
 ('''                Section("Modification (easier version)") {
                    TextEditor(text: $modification)
                        .frame(height: 80)
                }''', '''                Section("Modification (easier version)") {
                    TextEditor(text: $modification)
                        .frame(height: 80)
                }

                Section("Layer up (harder options, easiest first)") {
                    TextField("e.g. Pulse at the top → add a band → single leg", text: $layers, axis: .vertical)
                }'''),
 ('''                    modification = move.modification
                }''', '''                    modification = move.modification
                    layers = move.displayLayers
                }'''),
 ('''            buildingBlock: buildingBlock,
            modification: modification
        )
        libraryStore.addOrReplace(move)''', '''            buildingBlock: buildingBlock,
            modification: modification,
            style: editingMove?.style,
            layers: layers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : layers
        )
        libraryStore.addOrReplace(move)'''),
])

# ---------------- Builder: sides, arrange, layers
edit('iOS/ContentView.swift', [
 ('''struct DraftMove: Identifiable, Equatable {
    let id = UUID()
    var item: PilatesClassItem
}''', '''struct DraftMove: Identifiable, Equatable {
    let id = UUID()
    var item: PilatesClassItem
    /// Taught one side at a time. Saved as two timed moves: "(right)" then "(left)".
    var perSide = false
    /// How many timed blocks this move plays (2 when done right and left).
    var blocks: Int { perSide ? 2 : 1 }
}'''),
 ('''    private var totalSeconds: Int { moves.reduce(0) { $0 + $1.item.seconds } }''',
  '''    private var totalSeconds: Int { moves.reduce(0) { $0 + $1.item.seconds * $1.blocks } }'''),
 # arrange button in Time section
 ('''                    if !moves.isEmpty {
                        Button {
                            spreadEvenly()
                        } label: {''', '''                    if !moves.isEmpty {
                        Button {
                            withAnimation { arrangeForClass() }
                        } label: {
                            Label("Arrange in class order", systemImage: "list.number")
                        }
                        .foregroundStyle(Theme.rose)
                        Button {
                            spreadEvenly()
                        } label: {'''),
 ('''                    Text("Every move runs on time. Change one move's time by tapping it.")''',
  '''                    Text("Arrange in class order: warm-up stretches first, then each series together (standing, arms, core, glutes), cool-down stretches last. One-sided moves run on the right, then the same moves on the left. Every move runs on time.")'''),
 # row gets perSide
 ('''                            BuilderMoveRow(
                                number: index + 1,
                                item: move.item,''', '''                            BuilderMoveRow(
                                number: index + 1,
                                item: move.item,
                                perSide: move.perSide,'''),
 # library adds: sides + layers
 ('''                    moves += picked.map { libraryMove in
                        DraftMove(item: PilatesClassItem(
                            section: section,
                            name: libraryMove.name,
                            seconds: defaultSeconds,
                            cue: libraryMove.cue,
                            buildingBlock: libraryMove.buildingBlock,
                            modification: libraryMove.modification.isEmpty ? " " : libraryMove.modification,
                            props: libraryMove.props
                        ))
                    }''', '''                    moves += picked.map { libraryMove in
                        DraftMove(item: PilatesClassItem(
                            section: section,
                            name: libraryMove.name,
                            seconds: defaultSeconds,
                            cue: libraryMove.cue,
                            buildingBlock: libraryMove.buildingBlock,
                            modification: libraryMove.modification.isEmpty ? " " : libraryMove.modification,
                            layers: libraryMove.displayLayers,
                            props: libraryMove.props
                        ), perSide: Sidedness.isOneSided(libraryMove.name))
                    }'''),
 # Level I: sides
 ('''            moves = LevelIMatTemplate.exercises.map { DraftMove(item: $0) }''',
  '''            moves = LevelIMatTemplate.exercises.map { DraftMove(item: $0, perSide: Sidedness.isOneSided($0.name)) }'''),
 # edit: collapse right/left pairs
 ('''                var fixed = item
                if fixed.section.isEmpty && !carriedSection.isEmpty { fixed.section = carriedSection }
                return DraftMove(item: fixed)
            }''', '''                var fixed = item
                if fixed.section.isEmpty && !carriedSection.isEmpty { fixed.section = carriedSection }
                return DraftMove(item: fixed)
            }
            moves = collapseSides(moves)'''),
 # spread evenly counts blocks
 ('''        let each = max(15, Int((Double(targetSeconds) / Double(moves.count) / 5).rounded()) * 5)''',
  '''        let blocks = moves.reduce(0) { $0 + $1.blocks }
        let each = max(15, Int((Double(targetSeconds) / Double(blocks) / 5).rounded()) * 5)'''),
 # save: expand sides
 ('''        let items = moves.map { draft -> PilatesClassItem in
            var item = draft.item
            item.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if item.name.isEmpty { item.name = "Untitled move" }
            item.modification = item.modification.trimmingCharacters(in: .whitespacesAndNewlines)
            return item
        }''', '''        let cleaned = moves.map { draft -> DraftMove in
            var copy = draft
            copy.item.name = copy.item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if copy.item.name.isEmpty { copy.item.name = "Untitled move" }
            copy.item.modification = copy.item.modification.trimmingCharacters(in: .whitespacesAndNewlines)
            return copy
        }
        let items = expandSides(cleaned)'''),
 ('''    // WHAT: gives every move the same time so the class adds up''', '''    // WHAT: puts the moves in the order you'd teach them:
    //   1 Warm-Up (breathing, warm-ups, opening stretches)  2 Standing  3 Arms  4 Classical mat (classical order)
    //   5 Core  6 Glutes  7 Cool-Down (closing stretches, thank you).
    //   Moves stay in your order inside each group; one-sided moves are kept together so you switch sides once.
    //   Each move's section becomes its group name.
    // TO CHANGE: group order: the numbers in classGroup(). Opening stretches: openers.
    private func arrangeForClass() {
        let ranked = moves.enumerated().map { (offset, draft) -> (Int, Int, Int, String, DraftMove) in
            let group = classGroup(for: draft.item.name)
            let inner = group.rank == 4 ? classicalIndex(draft.item.name) : offset
            return (group.rank, draft.perSide ? 1 : 0, inner, group.label, draft)
        }
        moves = ranked
            .sorted { ($0.0, $0.1, $0.2) < ($1.0, $1.1, $1.2) }
            .map { rank, _, _, label, draft in
                var copy = draft
                copy.item.section = label
                return copy
            }
    }

    private let openers: Set<String> = ["cat & cow", "standing roll down", "neck & shoulder release", "seated side bend", "thread the needle"]

    private func classGroup(for name: String) -> (rank: Int, label: String) {
        let key = MoveNames.key(name)
        let library = libraryStore.moves.first { MoveNames.key($0.name) == key }
            ?? LibraryMoveSet.all.first { MoveNames.key($0.name) == key }
        if key.contains("welcome") || key.contains("check-in") { return (0, "Warm-Up") }
        if key.contains("thank you") || key.contains("closing") || key.contains("gift") { return (8, "Cool-Down") }
        if key.contains("breath") || key.contains("imprint") || openers.contains(key) || library?.area == .warmup {
            return (1, "Warm-Up")
        }
        if library?.style == .classical { return (4, "Classical Mat") }
        if library?.area == .stretch || key.contains("stretch") || key.contains("child's pose") || key.contains("roll down") {
            return (7, "Cool-Down")
        }
        let standingWords = ["squat", "lunge", "plié", "relevé", "deadlift", "skater", "curtsy", "chair pose", "standing", "walkout", "arabesque", "attitude", "balance"]
        if library?.style == .barre || library?.style == .standing || standingWords.contains(where: key.contains) {
            return (2, "Standing")
        }
        if let area = library?.area {
            switch area {
            case .arms: return (3, "Arms")
            case .core: return (5, "Core")
            case .glutes: return (6, "Glutes")
            default: break
            }
        }
        switch WorkoutSeries.infer(from: name) {
        case .lunge, .squat: return (2, "Standing")
        case .arms: return (3, "Arms")
        case .abs: return (5, "Core")
        }
    }

    /// Position of a classical move in the classical mat order (unknown moves go last, in your order).
    private func classicalIndex(_ name: String) -> Int {
        let key = MoveNames.key(name)
        let order = LibraryMoveSet.all.filter { $0.style == .classical }.map { MoveNames.key($0.name) }
        return order.firstIndex(of: key) ?? 1000
    }

    // WHAT: turns one-sided moves into timed blocks: all of a group's one-sided moves on the right, then the same moves on the left.
    //       Example: Clamshell, Side Kick → Clamshell (right), Side Kick (right), Clamshell (left), Side Kick (left).
    private func expandSides(_ drafts: [DraftMove]) -> [PilatesClassItem] {
        var result: [PilatesClassItem] = []
        var run: [DraftMove] = []
        func flush() {
            guard !run.isEmpty else { return }
            for (i, d) in run.enumerated() {
                var right = d.item
                right.name += " (right)"
                if i == run.count - 1 && right.transition.isEmpty { right.transition = "Switch to the left side." }
                result.append(right)
            }
            for d in run {
                var left = d.item
                left.name += " (left)"
                result.append(left)
            }
            run = []
        }
        for d in drafts {
            if d.perSide, run.isEmpty || run.last?.item.section == d.item.section {
                run.append(d)
            } else {
                flush()
                if d.perSide { run.append(d) } else { result.append(d.item) }
            }
        }
        flush()
        return result
    }

    // WHAT: when editing, shows "Move (right)" + "Move (left)" as one row marked R + L.
    private func collapseSides(_ drafts: [DraftMove]) -> [DraftMove] {
        var result: [DraftMove] = []
        var usedLeft = Set<Int>()
        for (i, d) in drafts.enumerated() {
            if usedLeft.contains(i) { continue }
            let name = d.item.name
            if name.hasSuffix(" (right)") {
                let base = String(name.dropLast(" (right)".count))
                if let j = drafts.indices.first(where: { $0 > i && !usedLeft.contains($0) && drafts[$0].item.name == base + " (left)" }) {
                    usedLeft.insert(j)
                    var merged = d
                    merged.item.name = base
                    if merged.item.transition == "Switch to the left side." { merged.item.transition = "" }
                    merged.perSide = true
                    result.append(merged)
                    continue
                }
            }
            result.append(d)
        }
        return result
    }

    // WHAT: gives every move the same time so the class adds up'''),
 # row view
 ('''private struct BuilderMoveRow: View {
    let number: Int
    let item: PilatesClassItem
    let showSection: Bool
''', '''private struct BuilderMoveRow: View {
    let number: Int
    let item: PilatesClassItem
    var perSide = false
    let showSection: Bool
'''),
 ('''                Spacer()
                Text(TimeFormat.mmss(item.seconds))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.rose)''', '''                Spacer()
                if perSide {
                    Text("R + L")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.gold.opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.brown)
                }
                Text(TimeFormat.mmss(item.seconds) + (perSide ? " each" : ""))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.rose)'''),
 # move editor: sides toggle + layers field
 ('''                    TextField("Section (e.g. Warm-Up, Mat flow)", text: $move.item.section)
''', '''                    TextField("Section (e.g. Warm-Up, Mat flow)", text: $move.item.section)
                    Toggle("One side at a time (right, then left)", isOn: $move.perSide)
                        .tint(Theme.rose)
'''),
 ('''                    TextField("Modification", text: $move.item.modification, axis: .vertical)
''', '''                    TextField("Modification (easier version)", text: $move.item.modification, axis: .vertical)
                    TextField("Layer up (harder options, easiest first)", text: $move.item.layers, axis: .vertical)
'''),
])
# label above time stepper in editor
edit('iOS/ContentView.swift', [
 ('''                        HStack {
                            Text("Time")
                            Spacer()
                            Text(TimeFormat.mmss(move.item.seconds))''', '''                        HStack {
                            Text(move.perSide ? "Time per side" : "Time")
                            Spacer()
                            Text(TimeFormat.mmss(move.item.seconds))'''),
])
print('flow applied')
