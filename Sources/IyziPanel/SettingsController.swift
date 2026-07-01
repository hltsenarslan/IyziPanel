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
        // Dock'ta ikon göstermemek için .accessory (agent) olarak kalıyoruz;
        // yalnızca pencereyi öne getirip aktifleştiriyoruz.
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
