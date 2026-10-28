// ======================================================================
// RunSessionController.swift  (Shared by iPhone + Watch)
// WHAT THIS FILE DOES: Connects the timer to the screens: refreshes 4 times a second and tells the screen the current and next move.
// TO CHANGE: Rarely needed.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation
import Combine

// WHAT: Runs the timer for a screen and tells it the current and next move.
@MainActor
final class RunSessionController: ObservableObject {
    @Published private(set) var snapshot: TimerSnapshot
    @Published private(set) var currentItem: PilatesClassItem?
    @Published private(set) var nextItemName: String = "-"

    let plan: PilatesClass
    let engine: TimerEngine

    private var ticker: AnyCancellable?
    private var previousSnapshot: TimerSnapshot?
    private var hapticHandler: ((TimerSnapshot, TimerSnapshot?) -> Void)?

    init(plan: PilatesClass) {
        self.plan = plan
        self.engine = TimerEngine(plan: plan)
        self.snapshot = engine.snapshot()
        self.currentItem = plan.items.first
        self.nextItemName = plan.items.count > 1 ? plan.items[1].name : "-"
    }

    func start(onTickHaptics: ((TimerSnapshot, TimerSnapshot?) -> Void)? = nil) {
        guard !plan.items.isEmpty else { return }
        hapticHandler = onTickHaptics
        engine.start()
        beginTicking()
        refresh()
    }

    func pauseResume() {
        if snapshot.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
        refresh()
    }

    func next() {
        engine.next()
        refresh()
    }

    func back() {
        engine.back()
        refresh()
    }

    func stop() {
        ticker?.cancel()
    }

    private func beginTicking() {
        ticker?.cancel()
        // WHAT: refresh the timer 4 times a second.
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    private func refresh() {
        let new = engine.snapshot()
        snapshot = new
        if !plan.items.isEmpty, new.currentIndex < plan.items.count {
            currentItem = plan.items[new.currentIndex]
            nextItemName = new.currentIndex + 1 < plan.items.count ? plan.items[new.currentIndex + 1].name : "-"
        } else {
            currentItem = nil
            nextItemName = "-"
        }
        hapticHandler?(new, previousSnapshot)
        previousSnapshot = new
    }
}
