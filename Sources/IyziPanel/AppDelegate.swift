import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = AppStore()
    private var dock: DockController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.load()
        dock = DockController(store: store)
        dock.start()

        // İlk çalıştırmada henüz uygulama seçilmediyse ayarları aç.
        if store.items.isEmpty {
            dock.openSettings()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
