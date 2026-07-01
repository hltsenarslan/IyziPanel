import Foundation
import ServiceManagement
import OSLog

/// Açılışta başlatma (Login Items) yönetimi. macOS 13+ SMAppService.
enum LoginItem {
    private static let log = Logger(subsystem: "tr.com.singleton.mac.iyzipanel", category: "login")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            log.error("Login item güncellenemedi: \(error.localizedDescription, privacy: .public)")
        }
    }
}
