"""Replaces the old iPhone class builders with one ClassBuilderView and turns on auto-sync to the watch."""
import sys, os
root = sys.argv[1]; tools = os.path.dirname(os.path.abspath(__file__))
def edit(path, pairs):
    full = os.path.join(root, path); s = open(full).read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:80], s.count(old))
        s = s.replace(old, new)
    open(full, 'w').write(s)

cv = os.path.join(root, 'iOS/ContentView.swift'); s = open(cv).read()
def cut(s, start, end):
    a = s.index(start); b = s.index(end, a); return s[:a] + s[b:]
# remove old builders (WorkoutBuilderView, ClassEditFormView, LevelIMatBuilderView..AddSectionView)
s = cut(s, '// WHAT: Quick workout builder:', '// WHAT: One class: name, minutes, props, the Start class button')
s = cut(s, '// MARK: - Class Edit Form\n', '// WHAT: One move on the class screen:')
part = open(os.path.join(tools, 'ClassBuilder.swift.part')).read()
a = s.index('// MARK: - Level I Mat Builder'); b = s.index('// MARK: - Library Tab')
s = s[:a] + part + s[b:]
open(cv, 'w').write(s)

edit('iOS/ContentView.swift', [
 # root: auto-send classes to the watch on launch and whenever they change
 ('''        .onChange(of: connectivity.latestWatchLogs) { _, logs in
            logStore.mergeRemote(logs)
        }
    }
}''', '''        .onChange(of: connectivity.latestWatchLogs) { _, logs in
            logStore.mergeRemote(logs)
        }
        // WHAT: keeps the watch up to date. Any new, edited or deleted class is sent to the watch automatically.
        .onChange(of: classStore.classes) { _, classes in
            connectivity.sendClasses(classes)
        }
        .task { connectivity.sendClasses(classStore.classes) }
    }
}'''),
 # class list: builder buttons
 ('''    @State private var showLevelIBuilder = false
    @State private var showCustomBuilder = false
''', '''    @State private var builder: BuilderStart?
'''),
 ('''                    ActionTile(title: "Level I", icon: "list.bullet.clipboard") { showLevelIBuilder = true }
                    ActionTile(title: "Custom", icon: "sparkles") { showCustomBuilder = true }''',
  '''                    ActionTile(title: "New class", icon: "plus") { builder = .blank }
                    ActionTile(title: "Level I", icon: "list.bullet.clipboard") { builder = .levelI }'''),
 ('''        .sheet(isPresented: $showLevelIBuilder) {
            LevelIMatBuilderView()
                .environmentObject(classStore)
        }
        .sheet(isPresented: $showCustomBuilder) {
            CustomClassBuilderView()
                .environmentObject(classStore)
                .environmentObject(libraryStore)
        }''', '''        .sheet(item: $builder) { start in
            ClassBuilderView(start: start)
                .environmentObject(classStore)
                .environmentObject(libraryStore)
        }'''),
 # class detail: always show the latest saved version; edit with the new builder; duplicate/delete
 ('''struct ClassDetailView: View {
    @EnvironmentObject private var classStore: ClassStore
    
    let plan: PilatesClass
    @State private var showEditForm = false
''', '''struct ClassDetailView: View {
    @EnvironmentObject private var classStore: ClassStore
    @EnvironmentObject private var libraryStore: LibraryStore
    @Environment(\\.dismiss) private var dismiss

    /// The class as it was when you opened it. `plan` below always reads the latest saved version.
    let opened: PilatesClass
    @State private var builder: BuilderStart?
    @State private var confirmDelete = false

    init(plan: PilatesClass) { opened = plan }

    // WHAT: the latest saved copy of this class, so edits show up right away.
    private var plan: PilatesClass {
        classStore.classes.first { $0.id == opened.id } ?? opened
    }
'''),
 ('''                    Button(action: { showEditForm = true }) {
                        Image(systemName: "pencil.circle.fill")''', '''                    Button(action: { builder = .edit(plan) }) {
                        Image(systemName: "pencil.circle.fill")'''),
 ('''        .sheet(isPresented: $showEditForm) {
            ClassEditFormView(classStore: classStore, editingClass: plan)
        }''', '''        .sheet(item: $builder) { start in
            ClassBuilderView(start: start)
                .environmentObject(classStore)
                .environmentObject(libraryStore)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { builder = .edit(plan) } label: { Label("Edit class", systemImage: "pencil") }
                    Button { classStore.duplicate(plan) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete class", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Delete \\(plan.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete class", role: .destructive) {
                classStore.delete(plan)
                dismiss()
            }
        } message: {
            Text("It will also be removed from your watch. Built-in classes come back the next time the app opens.")
        }'''),
])

edit('iOS/ClassStore.swift', [
 ('''    func importFromClipboard(''', '''    // WHAT: removes a class (and the watch copy, via auto-sync).
    func delete(_ classValue: PilatesClass) {
        classes.removeAll { $0.id == classValue.id }
        save()
    }

    // WHAT: makes a copy named "... (copy)" that you can change without touching the original.
    func duplicate(_ classValue: PilatesClass) {
        var copy = classValue
        copy.id = UUID().uuidString
        copy.version = 1
        copy.name = classValue.name + " (copy)"
        addOrReplace(copy)
    }

    func importFromClipboard('''),
])

edit('iOS/PhoneConnectivityManager.swift', [
 ('''    private let healthStore = HKHealthStore()
''', '''    private let healthStore = HKHealthStore()
    /// Classes waiting to go to the watch because the connection wasn't ready yet.
    private var pendingClasses: [PilatesClass]?
'''),
 ('''        guard WCSession.default.activationState == .activated else {
            syncStatus = "Watch session not active"
            return
        }
        do {
            let data = try JSONEncoder().encode(classes)
            let payload: [String: Any] = ["classesData": data]
            try WCSession.default.updateApplicationContext(payload)
            WCSession.default.transferUserInfo(payload)''', '''        guard WCSession.isSupported() else { return }
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
            WCSession.default.transferUserInfo(payload)'''),
 ('''    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}''',
  '''    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Send anything that was saved before the connection was ready.
        Task { @MainActor in
            if let pending = self.pendingClasses {
                self.pendingClasses = nil
                self.sendClasses(pending)
            }
        }
    }'''),
])
print('builder applied')
