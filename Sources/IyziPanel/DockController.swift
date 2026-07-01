import AppKit
import SwiftUI
import Combine

/// Panelin açık/kapalı durumunu SwiftUI'ye yansıtan gözlemlenebilir state.
final class DockState: ObservableObject {
    @Published var expanded = false
}

/// Kenar dock panelini yöneten kontrolcü: konumlandırma, aç/kapa animasyonu,
/// otomatik gizleme zamanlayıcısı ve uygulama başlatma.
final class DockController {
    // Ölçüler
    static let iconSize: CGFloat = 46
    static let iconInset: CGFloat = 10          // ikonun sağ/sol boşluğu
    static let barWidth: CGFloat = iconSize + iconInset * 2   // = 66
    static let collapsedPeek: CGFloat = 16      // kapalı kulbun genişliği
    static let handleHeight: CGFloat = 54       // kapalı kulbun yüksekliği (ekran boyu değil!)
    static let autoHideDelay: TimeInterval = 3

    private let store: AppStore
    private let state = DockState()
    private var panel: NSPanel!
    private var hideTimer: Timer?
    private var isExpanded = false
    private var settings: SettingsController?
    private var cancellables = Set<AnyCancellable>()

    init(store: AppStore) {
        self.store = store
    }

    func start() {
        buildPanel()
        positionPanel(expanded: false, animated: false)
        panel.orderFrontRegardless()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        // Ayarlardan kulp/bar konumu değişince canlı olarak yeniden konumlan.
        Publishers.Merge(
            store.$handlePositionRatio.map { _ in () },
            store.$barAnchor.map { _ in () }
        )
        .dropFirst()
        .sink { [weak self] _ in
            guard let self else { return }
            self.positionPanel(expanded: self.isExpanded, animated: true)
        }
        .store(in: &cancellables)
    }

    // MARK: - Panel kurulumu

    private func buildPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.barWidth, height: panelHeight()),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovable = false

        let root = DockBarView(
            store: store,
            state: state,
            onLaunch: { [weak self] in self?.launch($0) },
            onSettings: { [weak self] in self?.openSettings() },
            onHoverChange: { [weak self] in self?.hoverChanged($0) })

        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(x: 0, y: 0, width: Self.barWidth, height: panelHeight())
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        self.panel = panel
    }

    // MARK: - Konumlandırma

    private func panelHeight() -> CGFloat {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return min(640, screen.height * 0.7)
    }

    private func positionPanel(expanded: Bool, animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame
        let vf = screen.visibleFrame
        let width = expanded ? Self.barWidth : Self.collapsedPeek
        let height = expanded ? panelHeight() : Self.handleHeight

        // Kulbun merkez çizgisi: ratio 0 = üst, 1 = alt.
        let margin: CGFloat = 12
        let top = vf.maxY - margin
        let bottom = vf.minY + margin
        let desiredCenter = top - CGFloat(store.handlePositionRatio) * (top - bottom)
        let handleCenter = min(max(desiredCenter,
                                   vf.minY + Self.handleHeight / 2),
                               vf.maxY - Self.handleHeight / 2)

        // Bar'ın alt (origin) y'si: kulba göre anchor.
        let originY: CGFloat
        if expanded {
            switch store.barAnchor {
            case .center:
                originY = handleCenter - height / 2
            case .up:    // bar kulbun üstünde
                originY = handleCenter - Self.handleHeight / 2
            case .down:  // bar kulbun altında
                originY = handleCenter + Self.handleHeight / 2 - height
            }
        } else {
            originY = handleCenter - height / 2
        }
        let clampedY = min(max(originY, vf.minY), vf.maxY - height)

        let x = frame.maxX - width
        let target = NSRect(x: x, y: clampedY, width: width, height: height)

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
                panel.animator().setFrame(target, display: true)
            }
        } else {
            panel.setFrame(target, display: true)
        }
    }

    @objc private func screenChanged() {
        positionPanel(expanded: isExpanded, animated: false)
    }

    // MARK: - Aç / kapa

    private func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        state.expanded = true
        positionPanel(expanded: true, animated: true)
    }

    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        state.expanded = false
        positionPanel(expanded: false, animated: true)
    }

    private func hoverChanged(_ inside: Bool) {
        if inside {
            hideTimer?.invalidate()
            hideTimer = nil
            expand()
        } else {
            scheduleAutoHide()
        }
    }

    private func scheduleAutoHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(
            withTimeInterval: Self.autoHideDelay, repeats: false) { [weak self] _ in
            self?.collapse()
        }
    }

    // MARK: - Eylemler

    private func launch(_ item: AppItem) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        switch item.launchMode {
        case .activate:
            break
        case .newInstance:
            // Zaten açık olsa bile yeni bir kopya (destekleyen uygulamalar).
            config.createsNewApplicationInstance = true
        case .newWindow:
            // Mevcut kopyada yeni pencere aç (VS Code vb. Electron uygulamaları).
            config.arguments = ["--new-window"]
        }

        NSWorkspace.shared.openApplication(at: item.url, configuration: config) { _, error in
            if let error {
                NSLog("Uygulama açılamadı: \(error.localizedDescription)")
            }
        }
    }

    func openSettings() {
        if settings == nil {
            settings = SettingsController(store: store)
        }
        settings?.show()
    }
}
