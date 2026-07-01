import SwiftUI

/// Ayarlar arayüzü: solda dock (sürükle-sırala + sil), sağda kurulu uygulamalar.
struct SettingsView: View {
    @ObservedObject var store: AppStore
    @State private var installed: [AppItem] = []
    @State private var search = ""

    private var available: [AppItem] {
        let selected = Set(store.items.map(\.id))
        return installed.filter { app in
            !selected.contains(app.id) &&
            (search.isEmpty || app.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        TabView {
            appsTab
                .tabItem { Label("Uygulamalar", systemImage: "square.grid.2x2") }
            generalTab
                .tabItem { Label("Genel", systemImage: "gearshape") }
        }
        .padding(.top, 8)
        .frame(minWidth: 720, minHeight: 460)
        .onAppear { installed = InstalledApps.all() }
    }

    // MARK: - Sekme: Uygulamalar

    private var appsTab: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dock Uygulamaları")
                        .font(.headline)
                    Text("Sürükleyerek sırala, çıkarmak için – tuşuna bas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            HStack(spacing: 0) {
                dockColumn
                Divider()
                installedColumn
            }
        }
    }

    // MARK: - Sekme: Genel

    private var generalTab: some View {
        Form {
            Section("Başlangıç") {
                Toggle("Bilgisayar açılınca başlat", isOn: $store.launchAtLogin)
                Text("Kapalıysa uygulamayı elle açmanız gerekir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Kulp Konumu") {
                VStack(alignment: .leading, spacing: 6) {
                    Slider(value: $store.handlePositionRatio, in: 0...1) {
                        Text("Dikey konum")
                    } minimumValueLabel: {
                        Image(systemName: "arrow.up.to.line")
                    } maximumValueLabel: {
                        Image(systemName: "arrow.down.to.line")
                    }
                    HStack {
                        Button("Üst") { store.handlePositionRatio = 0.12 }
                        Button("Orta") { store.handlePositionRatio = 0.5 }
                        Button("Alt") { store.handlePositionRatio = 0.88 }
                        Spacer()
                        Text("%\(Int((1 - store.handlePositionRatio) * 100)) yukarıdan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            Section("Davranış") {
                LabeledContent("Otomatik gizleme", value: "\(Int(DockController.autoHideDelay)) sn")
                LabeledContent("Bar genişliği", value: "\(Int(DockController.barWidth)) px")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Sol sütun: seçili dock

    private var dockColumn: some View {
        VStack(spacing: 0) {
            if store.items.isEmpty {
                emptyState("Henüz uygulama eklemediniz.\nSağdaki listeden + ile ekleyin.")
            } else {
                List {
                    ForEach(store.items) { item in
                        AppRow(item: item, symbol: "minus.circle.fill", tint: .red) {
                            store.remove(item)
                        }
                    }
                    .onMove { store.move(from: $0, to: $1) }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 320)
    }

    // MARK: - Sağ sütun: kurulu uygulamalar

    private var installedColumn: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Kurulu uygulamalarda ara", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .padding(10)

            List {
                ForEach(available) { item in
                    AppRow(item: item, symbol: "plus.circle.fill", tint: .accentColor) {
                        store.add(item)
                    }
                }
            }
            .listStyle(.inset)
        }
        .frame(minWidth: 320)
    }

    private func emptyState(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
            Spacer()
        }
    }
}

/// Listelerde tek bir uygulama satırı (ikon + ad + aksiyon butonu).
private struct AppRow: View {
    let item: AppItem
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        HStack {
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 26, height: 26)
            Text(item.name)
            Spacer()
            Button(action: action) {
                Image(systemName: symbol).foregroundStyle(tint)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}
