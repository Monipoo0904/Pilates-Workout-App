import Foundation
import Combine
import WatchConnectivity

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var status: String = "Waiting for phone sync"
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

    private func ingest(context: [String: Any]) {
        guard let data = context["classesData"] as? Data,
              let classes = try? JSONDecoder().decode([PilatesClass].self, from: data) else { return }
        classStore?.replaceAll(classes)
        status = "Synced \(classes.count) class(es)"
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
            self.ingest(context: userInfo)
        }
    }
}
