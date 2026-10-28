import re, sys
root, part = sys.argv[1], open(sys.argv[2]).read()
def once(s, a, b, label):
    c = s.count(a); assert c == 1, (label, c); return s.replace(a, b)

# --- LogModels.swift ---
p = root + '/Shared/LogModels.swift'; s = open(p).read()
if 'enum MoveStyle' not in s:
    s = once(s, '    var modification: String\n\n    init(id: UUID = UUID(), name: String, area: ExerciseArea, props: [String] = [], reps: String = "", seconds: Int = 0, cue: String, buildingBlock: String, modification: String) {',
             '    var modification: String\n    /// Classical, contemporary, barre... nil for moves you add yourself.\n    var style: MoveStyle?\n\n    init(id: UUID = UUID(), name: String, area: ExerciseArea, props: [String] = [], reps: String = "", seconds: Int = 0, cue: String, buildingBlock: String, modification: String, style: MoveStyle? = nil) {', 'init')
    i = s.index('    init(id: UUID = UUID(), name: String, area: ExerciseArea')
    j = s.index('        self.modification = modification\n', i)
    s = s[:j] + '        self.modification = modification\n        self.style = style\n' + s[j+len('        self.modification = modification\n'):]
    i = s.index('static let levelIMat: [LibraryMove] = ['); j = s.index('\n    ]', i)
    block = s[i:j]
    block2, n = re.subn(r'(LibraryMove\(name: .*?)"\)(,?)$', r'\1", style: .classical)\2', block, flags=re.M)
    assert n >= 7, n
    s = s[:i] + block2 + s[j:]
    s = s.rstrip('\n') + '\n' + part
open(p, 'w').write(s)

# --- ClassStore.swift (LibraryStore) ---
p = root + '/iOS/ClassStore.swift'; s = open(p).read()
i = s.index('final class LibraryStore')
head, tail = s[:i], s[i:]
tail = once(tail, '            moves = LibraryMoveSet.levelIMat\n', '            moves = LibraryMoveSet.all\n', 'fallback')
a = tail.index('    private func mergeBuiltIns(into saved: [LibraryMove]) -> [LibraryMove] {')
b = tail.index('\n    }\n', a) + len('\n    }\n')
tail = tail[:a] + '''    /// Adds built-in moves you don't have yet (matched by name), removes duplicate
    /// copies of built-ins, and fills in the style on older saved copies.
    private func mergeBuiltIns(into saved: [LibraryMove]) -> [LibraryMove] {
        let builtIns = Dictionary(LibraryMoveSet.all.map { ($0.name.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
        var seenBuiltIns = Set<String>()
        var result: [LibraryMove] = []
        for var move in saved {
            let key = move.name.lowercased()
            if let builtIn = builtIns[key] {
                if seenBuiltIns.contains(key) { continue }
                seenBuiltIns.insert(key)
                if move.style == nil { move.style = builtIn.style }
            }
            result.append(move)
        }
        for move in LibraryMoveSet.all where !seenBuiltIns.contains(move.name.lowercased()) {
            result.append(move)
        }
        return result
    }
''' + tail[b:]
# also save when the merge changed anything
tail = once(tail, '        moves = mergeBuiltIns(into: decoded)\n        if moves.count != decoded.count { save() }',
            '        moves = mergeBuiltIns(into: decoded)\n        if moves != decoded { save() }', 'save')
s = head + tail
open(p, 'w').write(s)

# --- ContentView.swift (LibraryView style filter) ---
p = root + '/iOS/ContentView.swift'; s = open(p).read()
i = s.index('struct LibraryView: View {'); j = s.index('// MARK: - Move Row View', i)
v = s[i:j]
v = once(v, '    @State private var selectedProps: Set<String> = []\n', '    @State private var selectedProps: Set<String> = []\n    @State private var selectedStyles: Set<MoveStyle> = []\n', 'state')
v = once(v, '        // Filter by area\n', '''        // Filter by style
        if !selectedStyles.isEmpty {
            result = result.filter { move in
                guard let style = move.style else { return false }
                return selectedStyles.contains(style)
            }
        }

        // Filter by area
''', 'filter')
v = once(v, '                // Area filter\n', '''                // Style filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("STYLE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MoveStyle.allCases, id: \\.self) { style in
                                Button(action: {
                                    if selectedStyles.contains(style) {
                                        selectedStyles.remove(style)
                                    } else {
                                        selectedStyles.insert(style)
                                    }
                                }) {
                                    Text(style.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selectedStyles.contains(style) ? .white : Theme.brown)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedStyles.contains(style) ? Theme.gold : Color.white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedStyles.contains(style) ? Color.clear : Theme.gold.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Area filter
''', 'chips')
v = once(v, 'searchText.isEmpty && selectedAreas.isEmpty && selectedProps.isEmpty ?', 'searchText.isEmpty && selectedAreas.isEmpty && selectedProps.isEmpty && selectedStyles.isEmpty ?', 'empty')
s = s[:i] + v + s[j:]
open(p, 'w').write(s)
print('applied')
