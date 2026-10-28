// ======================================================================
// TimerEngine.swift  (Shared by iPhone + Watch)
// WHAT THIS FILE DOES: The class clock: works out which move you are on, time left in the move and in the class, pause/resume, next/back.
// TO CHANGE: Rarely needed. It always follows the order of moves in the class.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation

// WHAT: Everything the screens need to know about the timer right now.
struct TimerSnapshot: Equatable {
    var currentIndex: Int
    var currentItemRemaining: Int
    var currentItemElapsed: Int
    var classElapsed: Int
    var classRemaining: Int
    var totalClassSeconds: Int
    var currentItemEndAt: Date?
    var isPaused: Bool
    var isFinished: Bool
}

// WHAT: The class clock.
final class TimerEngine {
    private(set) var plan: PilatesClass
    private var cumulativeEnds: [Int] = []
    private var totalSeconds: Int = 0

    private var baseElapsed: TimeInterval = 0
    private var runningAnchor: Date?
    private var isPaused = true
    private(set) var startedAt: Date?
    private(set) var finishedAt: Date?

    init(plan: PilatesClass) {
        self.plan = plan
        rebuildTimeline()
    }

    func updatePlan(_ plan: PilatesClass) {
        self.plan = plan
        rebuildTimeline()
        reset()
    }

    func reset() {
        baseElapsed = 0
        runningAnchor = nil
        isPaused = true
        startedAt = nil
        finishedAt = nil
    }

    func start(now: Date = Date()) {
        guard !plan.items.isEmpty else { return }
        baseElapsed = 0
        runningAnchor = now
        isPaused = false
        startedAt = now
        finishedAt = nil
    }

    func pause(now: Date = Date()) {
        guard !isPaused, let anchor = runningAnchor else { return }
        baseElapsed += now.timeIntervalSince(anchor)
        runningAnchor = nil
        isPaused = true
    }

    func resume(now: Date = Date()) {
        guard isPaused && !isFinished(now: now), startedAt != nil else { return }
        runningAnchor = now
        isPaused = false
    }

    func next(now: Date = Date()) {
        let elapsed = elapsedSeconds(now: now)
        let index = itemIndex(forElapsed: elapsed)
        let nextStart = index + 1 < plan.items.count ? cumulativeStart(for: index + 1) : totalSeconds
        setElapsed(TimeInterval(nextStart), now: now)
    }

    func back(now: Date = Date()) {
        let elapsed = elapsedSeconds(now: now)
        let index = itemIndex(forElapsed: elapsed)
        let target = max(cumulativeStart(for: max(index - 1, 0)), 0)
        setElapsed(TimeInterval(target), now: now)
    }

    func snapshot(now: Date = Date()) -> TimerSnapshot {
        let elapsed = elapsedSeconds(now: now)
        let total = totalSeconds
        let finished = elapsed >= total
        if finished && finishedAt == nil {
            finishedAt = now
        }

        if plan.items.isEmpty {
            return TimerSnapshot(
                currentIndex: 0,
                currentItemRemaining: 0,
                currentItemElapsed: 0,
                classElapsed: 0,
                classRemaining: 0,
                totalClassSeconds: 0,
                currentItemEndAt: nil,
                isPaused: true,
                isFinished: true
            )
        }

        let boundedElapsed = min(elapsed, total)
        let idx = min(itemIndex(forElapsed: boundedElapsed), max(plan.items.count - 1, 0))
        let start = cumulativeStart(for: idx)
        let end = cumulativeEnds[idx]
        let itemElapsed = max(0, boundedElapsed - start)
        let itemRemaining = max(0, end - boundedElapsed)
        let classRemaining = max(0, total - boundedElapsed)

        return TimerSnapshot(
            currentIndex: idx,
            currentItemRemaining: itemRemaining,
            currentItemElapsed: itemElapsed,
            classElapsed: boundedElapsed,
            classRemaining: classRemaining,
            totalClassSeconds: total,
            currentItemEndAt: nil,
            isPaused: isPaused,
            isFinished: finished
        )
    }

    func isFinished(now: Date = Date()) -> Bool {
        elapsedSeconds(now: now) >= totalSeconds
    }

    private func elapsedSeconds(now: Date) -> Int {
        let elapsed: TimeInterval
        if let anchor = runningAnchor, !isPaused {
            elapsed = baseElapsed + now.timeIntervalSince(anchor)
        } else {
            elapsed = baseElapsed
        }
        return max(0, Int(elapsed.rounded(.down)))
    }

    private func setElapsed(_ value: TimeInterval, now: Date) {
        let bounded = min(max(value, 0), TimeInterval(totalSeconds))
        baseElapsed = bounded
        if isPaused {
            runningAnchor = nil
        } else {
            runningAnchor = now
        }
    }

    private func itemIndex(forElapsed elapsed: Int) -> Int {
        guard !cumulativeEnds.isEmpty else { return 0 }
        for (index, end) in cumulativeEnds.enumerated() where elapsed < end {
            return index
        }
        return max(cumulativeEnds.count - 1, 0)
    }

    private func cumulativeStart(for index: Int) -> Int {
        guard index > 0 else { return 0 }
        return cumulativeEnds[index - 1]
    }

    private func rebuildTimeline() {
        cumulativeEnds.removeAll(keepingCapacity: true)
        totalSeconds = 0
        for item in plan.items {
            totalSeconds += max(item.seconds, 0)
            cumulativeEnds.append(totalSeconds)
        }
    }
}
