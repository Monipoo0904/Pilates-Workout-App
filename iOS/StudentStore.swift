// xcode: set sdk=iOS

import Foundation
import Combine

// MARK: - StudentStore
/// Manages persistence of Student data.
/// Loads students from Documents/students.json on init.
/// Automatically saves after any add, update, or delete.
/// NOTE: decodeIfPresent() is used for backward compatibility, so old save files load gracefully.
///
/// USAGE:
///   @StateObject private var studentStore = StudentStore()
///   List(studentStore.students) { student in ... }
///   studentStore.addOrReplace(myStudent)
///   studentStore.delete(myStudent)
@MainActor
final class StudentStore: ObservableObject {
    // MARK: - Published State
    /// The current list of students, sorted alphabetically by name.
    /// Modify this via addOrReplace() or delete() to trigger auto-save.
    @Published private(set) var students: [Student] = []

    // MARK: - File Persistence
    /// Path to Documents/students.json
    private let fileURL: URL
    /// Encoders/decoders for JSON serialization
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init & Loading
    /// Initializes the store and loads students from disk.
    /// If the file doesn't exist or is invalid, starts with an empty list.
    /// - Parameter filename: Name of the JSON file (default: "students.json")
    init(filename: String = "students.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    /// Loads students from disk.
    /// If file is missing or corrupt, starts fresh with empty array.
    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([Student].self, from: data) else {
            students = []
            return
        }
        students = decoded
    }

    /// Saves the current students array to disk.
    /// Called automatically by addOrReplace() and delete().
    /// Manually call if you modify students directly (though you shouldn't).
    func save() {
        do {
            let data = try encoder.encode(students)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write students: \(error)")
        }
    }

    // MARK: - CRUD Operations
    /// Adds a new student or replaces an existing one (by id).
    /// Automatically sorts the list alphabetically and saves to disk.
    /// - Parameter student: The Student to add or update
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

    /// Deletes a student by id.
    /// Automatically saves to disk.
    /// - Parameter student: The Student to delete
    func delete(_ student: Student) {
        students.removeAll { $0.id == student.id }
        save()
    }

    // MARK: - Helper Methods
    /// Looks up a student's name by id.
    /// Useful for displaying student names in class logs without storing the full object.
    /// - Parameter id: The student's UUID
    /// - Returns: Student name if found, "Unknown" otherwise
    func studentName(for id: UUID) -> String {
        students.first { $0.id == id }?.name ?? "Unknown"
    }
}
