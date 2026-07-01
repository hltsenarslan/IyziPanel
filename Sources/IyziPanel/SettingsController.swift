import AppKit
import SwiftUI

/// Ayarlar penceresini (standart, odaklanabilir NSWindow) yönetir.
final class SettingsController: NSObject, NSWindowDelegate {
    private let store: AppStore
    private var window: NSWindow?

    init(store: AppStore) {
        self.store = store
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false)
            window.title = "IyziPanel Ayarları"
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: SettingsView(store: store))
            self.window = window
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Ayarlar kapanınca tekrar arka plan (agent) uygulamasına dön.
        NSApp.setActivationPolicy(.accessory)
    }
}
