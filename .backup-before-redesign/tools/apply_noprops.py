"""No-props: a mat-only version of every prop move, shown everywhere, filterable, and swappable in the builder."""
import sys, os, subprocess
root = sys.argv[1]; tools = os.path.dirname(os.path.abspath(__file__))
def edit(path, pairs):
    full = os.path.join(root, path); s = open(full).read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:90], s.count(old))
        s = s.replace(old, new)
    open(full, 'w').write(s)

tmp = os.path.join(tools, 'noprops.swift.part')
subprocess.run([sys.executable, os.path.join(tools, 'gen_noprops.py'), tmp], check=True)
edit('Shared/LogModels.swift', [
 ('    static var all: [LibraryMove] { levelIMat + moreStyles }', '    static var all: [LibraryMove] { levelIMat + moreStyles + NoProps.moves }'),
 ('''    static let names: Set<String> = [
''', '''    static let names: Set<String> = [
        "supine leg press", "supine hamstring stretch", "freestanding arabesque lift", "freestanding attitude lift",
        "curtsy lunge (no chair)", "freestanding side leg lift",
'''),
])
with open(os.path.join(root, 'Shared/LogModels.swift'), 'a') as f:
    f.write(open(tmp).read())

edit('iOS/ContentView.swift', [
 # class screen move card
 ('''                LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.berry)
            }''', '''                LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.berry)
            }
            if let noProps = NoProps.version(of: item.name) {
                LabeledNote(title: "No props", text: "\\(noProps.name): \\(noProps.cue)", icon: "hand.raised.fill", color: Theme.sage)
            }'''),
 # library detail card
 ('''                // Layer up (harder options)
                if !move.displayLayers.isEmpty {''', '''                // Without props
                if let noProps = NoProps.version(of: move.name) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Without props: \\(noProps.name)", systemImage: "hand.raised.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.berry)
                        Text(noProps.cue)
                            .font(.subheadline)
                            .foregroundStyle(Theme.brown)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }

                // Layer up (harder options)
                if !move.displayLayers.isEmpty {'''),
 # library tab prop filter
 ('''        if !selectedProps.isEmpty {
            result = result.filter { move in
                selectedProps.allSatisfy { prop in move.props.contains(prop) }
            }
        }''', '''        // "No props" shows mat-only moves.
        if !selectedProps.isEmpty {
            let realProps = selectedProps.subtracting(["No props"])
            result = result.filter { move in
                (!selectedProps.contains("No props") || move.props.isEmpty) &&
                realProps.allSatisfy { prop in move.props.contains(prop) }
            }
        }'''),
 ('''        Array(Set(libraryStore.moves.flatMap { $0.props })).sorted()''', '''        ["No props"] + Array(Set(libraryStore.moves.flatMap { $0.props })).sorted()'''),
 # builder library picker
 ('''                                Button("Any props") { prop = nil }''', '''                                Button("Any props") { prop = nil }
                                Button("No props") { prop = "No props" }'''),
 ('''            (prop == nil || move.props.contains { $0.lowercased() == prop!.lowercased() })''',
  '''            (prop == nil || (prop == "No props" ? move.props.isEmpty : move.props.contains { $0.lowercased() == prop!.lowercased() }))'''),
 # builder: swap whole class
 ('''                    } label: {
                        Label("Write my own move", systemImage: "square.and.pencil")
                    }''', '''                    } label: {
                        Label("Write my own move", systemImage: "square.and.pencil")
                    }
                    let propMoves = moves.filter { $0.withoutProps() != nil }.count
                    if propMoves > 0 {
                        Button {
                            withAnimation {
                                moves = moves.map { $0.withoutProps() ?? $0 }
                                if !moves.contains(where: { !$0.item.props.isEmpty }) { extraProps = "Mat" }
                            }
                        } label: {
                            Label("Make it prop-free (swap \\(propMoves) moves)", systemImage: "hand.raised")
                        }
                    }'''),
 # move editor: swap one move
 ('''                Section {
                    Button("Delete this move", role: .destructive) {''', '''                if let noProps = NoProps.version(of: move.item.name) {
                    Section("No props?") {
                        Button("Swap to \\(noProps.name)") {
                            if let swapped = move.withoutProps() { move = swapped }
                        }
                        .foregroundStyle(Theme.rose)
                    }
                }
                Section {
                    Button("Delete this move", role: .destructive) {'''),
 # helper
 ('''struct DraftMove: Identifiable, Equatable {''', '''// WHAT: the mat-only version of a move (same time and section), or nil if it needs no props.
extension DraftMove {
    func withoutProps() -> DraftMove? {
        guard let version = NoProps.version(of: item.name) else { return nil }
        var copy = self
        copy.item.name = version.name
        copy.item.cue = version.cue
        copy.item.setup = ""
        copy.item.buildingBlock = version.buildingBlock
        copy.item.modification = version.modification
        copy.item.layers = version.displayLayers
        copy.item.props = []
        copy.perSide = perSide || Sidedness.isOneSided(version.name)
        return copy
    }
}

struct DraftMove: Identifiable, Equatable {'''),
 ('''        let standingWords = ["squat",''', '''        let standingWords = ["hinge", "squat",'''),
])
edit('watchOS/WatchContentView.swift', [
 ('''                            LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.rose, textColor: .white)
                        }''', '''                            LabeledNote(title: "Layer up", text: item.displayLayers, icon: "plus.square.on.square", color: Theme.rose, textColor: .white)
                        }
                        if let noProps = NoProps.version(of: item.name) {
                            LabeledNote(title: "No props", text: noProps.name, icon: "hand.raised.fill", color: Theme.lightSage, textColor: .white)
                        }'''),
])
print('no-props applied')
