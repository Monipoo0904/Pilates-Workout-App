import Foundation

enum LogType: String, Codable, CaseIterable, Identifiable {
    case teaching
    case practice
    case observation

    var id: String { rawValue }
}

struct ClassLogEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var type: LogType
    var hours: Double
    var className: String
    var sourceDevice: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: LogType,
        hours: Double,
        className: String,
        sourceDevice: String
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.hours = hours
        self.className = className
        self.sourceDevice = sourceDevice
    }
}

enum TimeFormat {
    static func mmss(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func hoursRoundedQuarter(from seconds: Int) -> Double {
        let raw = Double(max(seconds, 0)) / 3600.0
        return (raw * 4.0).rounded() / 4.0
    }
}
