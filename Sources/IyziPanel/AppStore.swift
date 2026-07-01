import AppKit
import Combine

/// Kullanıcının seçtiği uygulamaları ve ayarları saklayan, kalıcı depoya
/// yazan gözlemlenebilir model.
final class AppStore: ObservableObject {
    @Published var items: [AppItem] = []
    @Published var launchAtLogin: Bool = false {
        didSet {
            guard !isLoading, launchAtLogin != oldValue else { return }
            LoginItem.setEnabled(launchAtLogin)
            save()
        }
    }

    /// Kulbun dikey konumu: 0 = üst, 0.5 = orta, 1 = alt.
    @Published var handlePositionRatio: Double = 0.5 {
        didSet {
            guard !isLoading, handlePositionRatio != oldValue else { return }
            save()
        }
    }

    /// Bar açıldığında kulba göre konumu.
    @Published var barAnchor: BarAnchor = .center {
        didSet {
            guard !isLoading, barAnchor != oldValue else { return }
            save()
        }
    }

    private var isLoading = false

    private struct Persisted: Codable {
        var items: [AppItem]
        var launchAtLogin: Bool
        var handlePositionRatio: Double?
        var barAnchor: BarAnchor?
    }

    private var configURL: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("IyziPanel", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("config.json")
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        // Login item'ın gerçek sistem durumunu kaynak-doğru kabul et.
        let systemLogin = LoginItem.isEnabled

        guard let data = try? Data(contentsOf: configURL),
              let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else {
            launchAtLogin = systemLogin
            return
        }
        items = decoded.items
        launchAtLogin = systemLogin
        handlePositionRatio = decoded.handlePositionRatio ?? 0.5
        barAnchor = decoded.barAnchor ?? .center
    }

    func save() {
        let payload = Persisted(
            items: items,
            launchAtLogin: launchAtLogin,
            handlePositionRatio: handlePositionRatio,
            barAnchor: barAnchor)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    // MARK: - Dock düzenleme

    func add(_ app: AppItem) {
        guard !items.contains(where: { $0.id == app.id }) else { return }
        items.append(app)
        save()
    }

    func remove(_ app: AppItem) {
        items.removeAll { $0.id == app.id }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func setLaunchMode(_ mode: LaunchMode, for app: AppItem) {
        guard let index = items.firstIndex(where: { $0.id == app.id }) else { return }
        items[index].launchMode = mode
        save()
    }
}
