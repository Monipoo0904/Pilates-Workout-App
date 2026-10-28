import Foundation
import Combine
import WatchConnectivity

@MainActor
final class PhoneConnectivityManager: NSObject, ObservableObject {
    @Published var syncStatus: String = "Not synced yet"
    @Published var latestWatchLogs: [ClassLogEntry] = []

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

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
}
