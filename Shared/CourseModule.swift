import Foundation

/// Represents a single module or checkpoint in your Peak Pilates Level I certification.
/// Modules s01–s10 cover curriculum topics. Theoretical and Practical are final exams/assessments.
/// Each module tracks completion status, date completed, and personal notes.
struct CourseModule: Codable, Identifiable, Hashable {
    // MARK: - Core Fields
    /// Unique identifier: "s01"–"s10" for modules, "theoretical"/"practical" for exams
    var id: String
    /// Module title (e.g., "Principles of Movement")
    var title: String
    
    // MARK: - Status Tracking
    /// True when module is marked complete
    var done: Bool
    /// Date the module was completed (optional, useful for tracking progress over time)
    var completedDate: Date?
    /// Personal notes (reflection, key takeaways, areas to review, etc.)
    var notes: String?

    init(
        id: String,
        title: String,
        done: Bool = false,
        completedDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.done = done
        self.completedDate = completedDate
        self.notes = notes
    }
}

// MARK: - Seeded Course Data
/// Contains all 12 course modules for Peak Pilates Level I certification.
/// Used to initialize CourseStore on first launch.
/// MODIFY this list to add, remove, or change module titles/IDs.
enum CourseModuleSet {
    static let standard: [CourseModule] = [
        // MARK: - Module 1–10: Curriculum
        CourseModule(id: "s01", title: "Principles of Movement"),
        CourseModule(id: "s02", title: "Basic Mat Work"),
        CourseModule(id: "s03", title: "Breathing Techniques"),
        CourseModule(id: "s04", title: "Core Engagement"),
        CourseModule(id: "s05", title: "Flow & Transitions"),
        CourseModule(id: "s06", title: "Modifications & Progressions"),
        CourseModule(id: "s07", title: "Class Structure & Cueing"),
        CourseModule(id: "s08", title: "Common Injuries & Adaptations"),
        CourseModule(id: "s09", title: "Music & Pacing"),
        CourseModule(id: "s10", title: "Teaching Strategies"),
        
        // MARK: - Final Assessments
        CourseModule(id: "theoretical", title: "Theoretical Exam (50 questions, 60 min, pass 40)"),
        CourseModule(id: "practical", title: "Practical Assessment"),
    ]
}
