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

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // WHAT: sends all your classes to the watch (the "Send to Watch" button).
    func sendClasses(_ classes: [PilatesClass]) {
        guard WCSession.default.activationState == .activated else {
            syncStatus = "Watch session not active"
            return
        }
        do {
            let data = try JSONEncoder().encode(classes)
            let payload: [String: Any] = ["classesData": data]
            try WCSession.default.updateApplicationContext(payload)
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
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

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
