import sys
root, block = sys.argv[1], open(sys.argv[2]).read()
def once(s, a, b, label):
    c = s.count(a); assert c == 1, (label, c); return s.replace(a, b)
# 1) Keep the order a class was written in
p = root + '/Shared/PilatesModels.swift'; s = open(p).read()
i = s.index('    var orderedItems: [PilatesClassItem] {'); j = s.index('\n    }\n', i) + len('\n    }\n')
s = s[:i] + '''    /// Moves in teaching order: exactly the order the class was written in.
    /// (Never sort here; the timer, the class screen and the watch all follow this order.)
    var orderedItems: [PilatesClassItem] {
        items
    }
''' + s[j:]
open(p, 'w').write(s)
# 2) Fall Into Pilates in the right order + built-in updates reach saved copies
p = root + '/Shared/SampleData.swift'; s = open(p).read()
i = s.index('    static let fallIntoPilates = PilatesClass('); j = s.index('\n    )\n', i) + len('\n    )\n')
s = s[:i] + block + s[j:]
i = s.index('    static func mergingBuiltIns(into saved: [PilatesClass]) -> [PilatesClass] {'); j = s.index('\n    }\n', i) + len('\n    }\n')
s = s[:i] + '''    /// Adds missing built-in classes, and replaces a saved built-in with the newer
    /// version when its version number goes up (so fixes reach the phone and the watch).
    static func mergingBuiltIns(into saved: [PilatesClass]) -> [PilatesClass] {
        let latest = Dictionary(builtIns.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let updated = saved.map { savedClass -> PilatesClass in
            if let builtIn = latest[savedClass.id], builtIn.version > savedClass.version { return builtIn }
            return savedClass
        }
        let ids = Set(saved.map(\\.id))
        return updated + builtIns.filter { !ids.contains($0.id) }
    }
''' + s[j:]
open(p, 'w').write(s)
print('order fixed')
