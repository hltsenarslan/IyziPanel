import AppKit

// IyziPanel — kenar dock uygulaması.
// Agent (menü çubuğunda / dock'ta görünmeyen) bir uygulama olarak çalışır.

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
