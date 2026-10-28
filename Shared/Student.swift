import Foundation

/// Represents a student in your teaching practice.
/// Store contact info, injuries/limitations, goals, and notes for each student.
/// Used for logging teaching sessions and tracking individual progress.
struct Student: Codable, Identifiable, Hashable {
    // MARK: - Core Fields
    /// Unique identifier for the student
    var id: UUID
    /// Student's name
    var name: String
    
    // MARK: - Optional Details
    /// Phone, email, or other contact method
    var contact: String?
    /// Injuries, physical limitations, or contraindications to note during class
    var injuries: String?
    /// Student's fitness/Pilates goals
    var goals: String?
    /// Any additional notes (availability, preferences, progress notes, etc.)
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        contact: String? = nil,
        injuries: String? = nil,
        goals: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.contact = contact
        self.injuries = injuries
        self.goals = goals
        self.notes = notes
    }
}
