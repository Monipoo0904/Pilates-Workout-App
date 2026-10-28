// ======================================================================
// WatchConnectivityManager.swift  (Apple Watch app)
// WHAT THIS FILE DOES: Receives classes and "start this class" messages from the iPhone, and sends watch logs back.
// TO CHANGE: How old a start request can be before it is ignored: see the TO CHANGE note in handleCommand().
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation
import Combine
import WatchConnectivity

/// A class the iPhone asked the watch to start.
// WHAT: A class the iPhone asked the watch to start.
struct StartRequest: Identifiable, Equatable {
    let id = UUID()
    let plan: PilatesClass
}

// WHAT: Watch side of the iPhone <-> Watch connection.
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var status: String = "Waiting for phone sync"
    @Published var startRequest: StartRequest?
    weak var classStore: WatchClassStore?
    weak var logStore: WatchLogStore?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendLogsToPhone() {
        guard WCSession.default.activationState == .activated else { return }
        guard let logStore,
              let data = try? JSONEncoder().encode(logStore.logs) else { return }
        WCSession.default.transferUserInfo(["logEntries": data])
    }

    func tellPhoneClassStarted() {
        guard WCSession.default.activationState == .activated, WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["event": "classStarted"], replyHandler: nil, errorHandler: nil)
    }

    private func ingest(context: [String: Any]) {
        guard let data = context["classesData"] as? Data,
              let classes = try? JSONDecoder().decode([PilatesClass].self, from: data) else { return }
        classStore?.replaceAll(classes)
        status = "Synced \(classes.count) class(es)"
    }

    /// Handles "start this class" from the iPhone. Returns true if the payload was a command.
    private func handleCommand(_ info: [String: Any]) -> Bool {
        guard info["command"] as? String == "startClass" else { return false }
        let sentAt = info["sentAt"] as? TimeInterval ?? 0
        // Ignore old requests that were queued while the watch was away.
        // TO CHANGE: ignore start requests older than 2 hours (2 * 60 * 60 seconds).
        guard Date().timeIntervalSince1970 - sentAt < 2 * 60 * 60,
              let data = info["classData"] as? Data,
              let plan = try? JSONDecoder().decode(PilatesClass.self, from: data) else { return true }
        startRequest = StartRequest(plan: plan)
        status = "Started from iPhone"
        return true
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.ingest(context: applicationContext)
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            if !self.handleCommand(userInfo) {
                self.ingest(context: userInfo)
            }
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            _ = self.handleCommand(message)
        }
    }
}
