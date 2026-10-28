import re, sys
root = sys.argv[1]
seed = open(sys.argv[2]).read()

# 1) LogModels.swift: real course titles + seed data
p = root + '/Shared/LogModels.swift'
s = open(p).read()
titles = {
 "s01": "Section 1: Welcome to Level I Classical Mat", "s02": "Section 2: The Mat is the Method",
 "s03": "Section 3: Peak Pilates® Foundations", "s04": "Section 4: The Science of Movement",
 "s05": "Section 5: Mat Technique Basics", "s06": "Section 6: Optional Class Add-Ins",
 "s07": "Section 7: The Art of Teaching", "s08": "Section 8: Theoretical Exam",
 "s09": "Section 9: Practical Assessment", "s10": "Conclusion: feedback & evaluation"}
n = 0
for k, t in titles.items():
    s, c = re.subn(r'CourseModule\(id: "%s", title: "[^"]*"\)' % k, 'CourseModule(id: "%s", title: "%s")' % (k, t), s)
    n += c
assert n == 10, n
if 'enum WebTrackerImport' not in s:
    s = s.rstrip('\n') + '\n' + seed
open(p, 'w').write(s)

# 2) LogStore.swift
p = root + '/iOS/LogStore.swift'
s = open(p).read()
if 'importWebTrackerIfNeeded' not in s:
    a = '        fileURL = docs.appendingPathComponent(filename)\n        load()\n'
    assert s.count(a) == 1
    s = s.replace(a, a + '        importWebTrackerIfNeeded()\n')
    b = '    private func save() {'
    assert s.count(b) == 1
    s = s.replace(b, '''    /// Adds the sessions logged in the web tracker, once.
    private func importWebTrackerIfNeeded() {
        let key = "didImportWebTrackerLogs.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let existing = Set(logs.map(\\.id))
        let new = WebTrackerImport.sessions.filter { !existing.contains($0.id) }
        if !new.isEmpty {
            logs = (logs + new).sorted { $0.date > $1.date }
            save()
        }
        UserDefaults.standard.set(true, forKey: key)
    }

''' + b)
open(p, 'w').write(s)

# 3) ClassStore.swift: StudentStore + CourseStore
p = root + '/iOS/ClassStore.swift'
s = open(p).read()
if 'importWebTrackerIfNeeded' not in s:
    for fname in ['students.json', 'course.json']:
        a = 'init(filename: String = "%s") {' % fname
        i = s.index(a)
        j = s.index('        load()\n', i) + len('        load()\n')
        s = s[:j] + '        importWebTrackerIfNeeded()\n' + s[j:]
    # StudentStore method, inserted before its save()
    i = s.index('final class StudentStore'); j = s.index('    func save() {', i)
    s = s[:j] + '''    /// Adds the students from the web tracker, once.
    private func importWebTrackerIfNeeded() {
        let key = "didImportWebTrackerStudents.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let names = Set(students.map { $0.name.lowercased() })
        let new = WebTrackerImport.students.filter { !names.contains($0.name.lowercased()) }
        if !new.isEmpty {
            students = (students + new).sorted { $0.name.lowercased() < $1.name.lowercased() }
            save()
        }
        UserDefaults.standard.set(true, forKey: key)
    }

''' + s[j:]
    i = s.index('final class CourseStore'); j = s.index('    func save() {', i)
    s = s[:j] + '''    /// Uses the real Peak course section names and the progress from the web tracker, once.
    private func importWebTrackerIfNeeded() {
        let key = "didImportWebTrackerCourse.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        for module in WebTrackerImport.modules {
            if let index = modules.firstIndex(where: { $0.id == module.id }) {
                modules[index].title = module.title
                modules[index].notes = module.notes
                if module.done { modules[index].done = true }
            } else {
                modules.append(module)
            }
        }
        save()
        UserDefaults.standard.set(true, forKey: key)
    }

''' + s[j:]
open(p, 'w').write(s)
print('applied')
