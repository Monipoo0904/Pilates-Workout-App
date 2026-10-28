import Foundation
import SwiftUI

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

extension PilatesClass {
    var minutesLabel: String { "\(Int((Double(totalSeconds) / 60).rounded())) min" }
}

// MARK: - Theme (matches the Fall Into Pilates flyer and MyVillage Project colors)

enum Theme {
    static let blush = Color(hex: 0xFBE4EA)
    static let petal = Color(hex: 0xF6C1D1)
    static let rose = Color(hex: 0xD1457A)
    static let berry = Color(hex: 0x7D2350)
    static let cream = Color(hex: 0xFFF7F5)
    static let gold = Color(hex: 0xB88D2D)
    static let brown = Color(hex: 0x4E3729)
    static let sage = Color(hex: 0x5F7D5A)
    static let lightSage = Color(hex: 0xA8C3A0)
    static let clay = Color(hex: 0xB5532F)
    static let peach = Color(hex: 0xF4A582)

    /// Serif italic headline, like the flyer.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .serif).italic()
    }

    static let background = LinearGradient(colors: [cream, blush], startPoint: .top, endPoint: .bottom)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

struct Chip: View {
    let text: String
    var tint: Color = Theme.rose

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct TimerRing: View {
    /// Fraction elapsed, 0...1.
    let progress: Double
    var lineWidth: CGFloat = 14
    var track: Color = Theme.petal
    var tint: Color = Theme.rose

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
        }
    }
}

struct LabeledNote: View {
    let title: String
    let text: String
    let icon: String
    let color: Color
    var textColor: Color = Theme.brown

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.bold)).foregroundStyle(color)
                Text(text).font(.footnote).foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum ClassAlerts {
    static let tenMinutes = 600

    /// True at the moment the class crosses the 10-minutes-left mark.
    static func crossedTenMinutes(old: Int, new: Int, total: Int) -> Bool {
        total > tenMinutes && old > tenMinutes && new <= tenMinutes && new > 0
    }
}
