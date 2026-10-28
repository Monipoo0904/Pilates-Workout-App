// ======================================================================
// PhoneConnectivityManager.swift  (iPhone app)
// WHAT THIS FILE DOES: Talks to the Apple Watch: sends your classes, opens the watch app when a class starts, and receives watch logs.
// TO CHANGE: Change the status messages shown on the phone here.
// Step-by-step help: HOW-TO-EDIT.md in the project folder.
// ======================================================================

import Foundation
import Combine
import HealthKit
import WatchConnectivity

// WHAT: iPhone side of the iPhone <-> Watch connection.
@MainActor
final class PhoneConnectivityManager: NSObject, ObservableObject {
    @Published var syncStatus: String = "Not synced yet"
    @Published var watchStatus: String = ""
    @Published var latestWatchLogs: [ClassLogEntry] = []

    private let healthStore = HKHealthStore()
    /// Classes waiting to go to the watch because the connection wasn't ready yet.
    private var pendingClasses: [PilatesClass]?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // WHAT: sends all your classes to the watch (the "Send to Watch" button).
    func sendClasses(_ classes: [PilatesClass]) {
        guard WCSession.isSupported() else { return }
        guard WCSession.default.activationState == .activated else {
            // Not connected yet: remember these and send them as soon as the connection is ready.
            pendingClasses = classes
            syncStatus = "Will sync when your watch connects"
            return
        }
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else {
            syncStatus = "Install Pilates Timer on your Apple Watch to sync"
            return
        }
        do {
            let data = try JSONEncoder().encode(classes)
            let payload: [String: Any] = ["classesData": data]
            try WCSession.default.updateApplicationContext(payload)
            // Only the newest class list matters: cancel older queued copies, then queue this one.
            for transfer in WCSession.default.outstandingUserInfoTransfers where transfer.userInfo["classesData"] != nil {
                transfer.cancel()
            }
            WCSession.default.transferUserInfo(payload)
            syncStatus = "Synced \(classes.count) class(es)"
        } catch {
            syncStatus = "Sync failed: \(error.localizedDescription)"
        }
    }

    /// Opens Pilates Timer on the paired Apple Watch and starts the same class there.
    func startClassOnWatch(_ plan: PilatesClass) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            watchStatus = "Apple Watch not connected"
            return
        }
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else {
            watchStatus = "Install Pilates Timer on your Apple Watch"
            return
        }

        // 1. Wake the watch app with a Pilates workout (needs the HealthKit capability).
        if HKHealthStore.isHealthDataAvailable() {
            let config = HKWorkoutConfiguration()
            config.activityType = .pilates
            config.locationType = .unknown
            healthStore.startWatchApp(with: config) { success, _ in
                if !success {
                    Task { @MainActor in
                        self.watchStatus = "Open Pilates Timer on your watch to follow along"
                    }
                }
            }
        }

        // 2. Tell the watch which class to run.
        guard let data = try? JSONEncoder().encode(plan) else { return }
        let payload: [String: Any] = [
            "command": "startClass",
            "classData": data,
            "sentAt": Date().timeIntervalSince1970
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
        watchStatus = "Starting on your Apple Watch…"
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {}
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Send anything that was saved before the connection was ready.
        Task { @MainActor in
            if let pending = self.pendingClasses {
                self.pendingClasses = nil
                self.sendClasses(pending)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["logEntries"] as? Data,
              let entries = try? JSONDecoder().decode([ClassLogEntry].self, from: data) else { return }
        Task { @MainActor in
            self.latestWatchLogs = entries
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message["event"] as? String == "classStarted" else { return }
        Task { @MainActor in
            self.watchStatus = "Running on your Apple Watch"
        }
    }
}
