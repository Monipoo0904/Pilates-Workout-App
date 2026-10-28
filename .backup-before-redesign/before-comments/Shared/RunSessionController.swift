import Foundation
import Combine

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
