// xcode: set sdk=iOS

import Foundation
import Combine

@MainActor
final class ClassStore: ObservableObject {
    @Published private(set) var classes: [PilatesClass] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "classes.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PilatesClass].self, from: data) else {
            classes = SampleData.builtIns
            save()
            return
        }
        let merged = SampleData.mergingBuiltIns(into: decoded)
        classes = merged
        if merged.count != decoded.count { save() }
    }

    func save() {
        do {
            let data = try encoder.encode(classes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write classes: \(error)")
        }
    }

    func addOrReplace(_ classValue: PilatesClass) {
        let normalized = classValue.reorderedBySeries()
        if let index = classes.firstIndex(where: { $0.id == normalized.id }) {
            classes[index] = normalized
        } else {
            classes.append(normalized)
        }
        classes.sort { lhs, rhs in
            lhs.name.lowercased() < rhs.name.lowercased()
        }
        save()
    }

    func importFromClipboard(_ text: String) throws -> PilatesClass {
        guard let data = text.data(using: .utf8) else { throw ClassImportError.invalidJSON }
        let parsed = try ClassImportValidator.parseClass(from: data)
        addOrReplace(parsed)
        return parsed
    }

    func importFile(_ url: URL) throws -> PilatesClass {
        let data = try Data(contentsOf: url)
        let parsed = try ClassImportValidator.parseClass(from: data)
        addOrReplace(parsed)
        return parsed
    }
}

// MARK: - StudentStore
@MainActor
final class StudentStore: ObservableObject {
    @Published private(set) var students: [Student] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "students.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([Student].self, from: data) else {
            students = []
            return
        }
        students = decoded
    }

    func save() {
        do {
            let data = try encoder.encode(students)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write students: \(error)")
        }
    }

    func addOrReplace(_ student: Student) {
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index] = student
        } else {
            students.append(student)
        }
        students.sort { lhs, rhs in
            lhs.name.lowercased() < rhs.name.lowercased()
        }
        save()
    }

    func delete(_ student: Student) {
        students.removeAll { $0.id == student.id }
        save()
    }

    func studentName(for id: UUID) -> String {
        students.first { $0.id == id }?.name ?? "Unknown"
    }
}

// MARK: - CourseStore
@MainActor
final class CourseStore: ObservableObject {
    @Published private(set) var modules: [CourseModule] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "course.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([CourseModule].self, from: data) else {
            modules = CourseModuleSet.standard
            save()
            return
        }
        modules = mergeBuiltIns(into: decoded)
        if modules.count != decoded.count { save() }
    }

    func save() {
        do {
            let data = try encoder.encode(modules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write course modules: \(error)")
        }
    }

    func toggleModule(_ module: CourseModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index].done = !modules[index].done
            if modules[index].done {
                modules[index].completedDate = Date()
            } else {
                modules[index].completedDate = nil
            }
            save()
        }
    }

    func addOrReplace(_ module: CourseModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
        } else {
            modules.append(module)
        }
        save()
    }

    var completionProgress: Double {
        guard !modules.isEmpty else { return 0 }
        let done = modules.filter { $0.done }.count
        return Double(done) / Double(modules.count)
    }

    private func mergeBuiltIns(into saved: [CourseModule]) -> [CourseModule] {
        let standard = CourseModuleSet.standard
        var result = saved
        for standard in standard {
            if !result.contains(where: { $0.id == standard.id }) {
                result.append(standard)
            }
        }
        return result
    }
}

// MARK: - LibraryStore
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var moves: [LibraryMove] = []
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "library.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([LibraryMove].self, from: data) else {
            moves = LibraryMoveSet.levelIMat
            save()
            return
        }
        moves = mergeBuiltIns(into: decoded)
        if moves.count != decoded.count { save() }
    }

    func save() {
        do {
            let data = try encoder.encode(moves)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write library: \(error)")
        }
    }

    func addOrReplace(_ move: LibraryMove) {
        if let index = moves.firstIndex(where: { $0.id == move.id }) {
            moves[index] = move
        } else {
            moves.append(move)
        }
        save()
    }

    func delete(_ move: LibraryMove) {
        moves.removeAll { $0.id == move.id }
        save()
    }

    func moves(in area: ExerciseArea) -> [LibraryMove] {
        moves.filter { $0.area == area }
            .sorted { lhs, rhs in lhs.name.lowercased() < rhs.name.lowercased() }
    }

    private func mergeBuiltIns(into saved: [LibraryMove]) -> [LibraryMove] {
        let builtIn = LibraryMoveSet.levelIMat
        var result = saved
        for built in builtIn {
            if !result.contains(where: { $0.id == built.id }) {
                result.append(built)
            }
        }
        return result
    }
}
