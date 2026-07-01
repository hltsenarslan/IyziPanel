import AppKit

/// Sistemde kurulu uygulamaları tarar.
enum InstalledApps {
    private static let searchDirs: [String] = [
        "/Applications",
        "/Applications/Utilities",
        "/System/Applications",
        "/System/Applications/Utilities",
        NSHomeDirectory() + "/Applications"
    ]

    static func all() -> [AppItem] {
        let fm = FileManager.default
        var seen = Set<String>()
        var result: [AppItem] = []

        for dir in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries where entry.hasSuffix(".app") {
                let path = (dir as NSString).appendingPathComponent(entry)
                guard let bundle = Bundle(path: path) else { continue }
                let id = bundle.bundleIdentifier ?? path
                guard !seen.contains(id) else { continue }
                seen.insert(id)

                let name = (bundle.infoDictionary?["CFBundleName"] as? String)
                    ?? (entry as NSString).deletingPathExtension
                result.append(AppItem(id: id, name: name, path: path))
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
