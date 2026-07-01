import AppKit

/// Bar açıldığında kulba göre nerede belireceği.
enum BarAnchor: String, Codable, CaseIterable, Identifiable {
    case up        // Kulptan yukarı doğru açılır
    case center    // Kulpla ortalı
    case down      // Kulptan aşağı doğru açılır

    var id: String { rawValue }

    var label: String {
        switch self {
        case .up: return "Kulptan yukarı"
        case .center: return "Kulpla ortalı"
        case .down: return "Kulptan aşağı"
        }
    }
}

/// İkona tıklanınca uygulamanın nasıl açılacağı.
enum LaunchMode: String, Codable, CaseIterable, Identifiable {
    case activate      // Açıksa öne getir, değilse aç
    case newInstance   // Her tıklamada yeni bir kopya (destekleyen uygulamalar)
    case newWindow     // Mevcut kopyada yeni pencere (--new-window; VS Code vb.)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .activate: return "Etkinleştir"
        case .newInstance: return "Yeni instance"
        case .newWindow: return "Yeni pencere"
        }
    }
}

/// Dock'ta veya kurulu uygulamalar listesinde tutulan tek bir uygulama.
struct AppItem: Identifiable, Codable, Hashable {
    var id: String       // Bundle identifier (yoksa dosya yolu)
    var name: String
    var path: String
    var launchMode: LaunchMode = .newInstance

    init(id: String, name: String, path: String, launchMode: LaunchMode = .newInstance) {
        self.id = id
        self.name = name
        self.path = path
        self.launchMode = launchMode
    }

    // Geriye dönük uyum: eski config'lerde launchMode alanı yoktu.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        path = try c.decode(String.self, forKey: .path)
        launchMode = try c.decodeIfPresent(LaunchMode.self, forKey: .launchMode) ?? .newInstance
    }

    var url: URL { URL(fileURLWithPath: path) }

    /// Finder ikonu (Codable değil, ihtiyaç anında yüklenir).
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }
}
