import AppKit

/// Dock'ta veya kurulu uygulamalar listesinde tutulan tek bir uygulama.
struct AppItem: Identifiable, Codable, Hashable {
    var id: String       // Bundle identifier (yoksa dosya yolu)
    var name: String
    var path: String

    var url: URL { URL(fileURLWithPath: path) }

    /// Finder ikonu (Codable değil, ihtiyaç anında yüklenir).
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }
}
