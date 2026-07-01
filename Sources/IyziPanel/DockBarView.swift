import SwiftUI

/// Kenardaki tutamak + glass bar. Hover durumunu kontrolcüye bildirir.
struct DockBarView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var state: DockState
    var onLaunch: (AppItem) -> Void
    var onSettings: () -> Void
    var onHoverChange: (Bool) -> Void

    var body: some View {
        Group {
            if state.expanded {
                bar
            } else {
                handle
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { onHoverChange($0) }
    }

    // MARK: - Glass bar

    private var bar: some View {
        VStack(spacing: 10) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(store.items) { item in
                        AppIconButton(item: item) { onLaunch(item) }
                    }
                }
                .padding(.vertical, 12)
            }

            Spacer(minLength: 0)

            SettingsButton(action: onSettings)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .hudWindow)
        )
        .clipShape(
            .rect(topLeadingRadius: 22, bottomLeadingRadius: 22,
                  bottomTrailingRadius: 0, topTrailingRadius: 0)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 22, bottomLeadingRadius: 22,
                bottomTrailingRadius: 0, topTrailingRadius: 0)
            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Kapalı kulp (küçük glass pill + sola oklar)

    private var handle: some View {
        ZStack {
            VisualEffectView(material: .hudWindow)
            Image(systemName: "chevron.compact.left")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .clipShape(
            .rect(topLeadingRadius: 8, bottomLeadingRadius: 8,
                  bottomTrailingRadius: 0, topTrailingRadius: 0)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 8, bottomLeadingRadius: 8,
                bottomTrailingRadius: 0, topTrailingRadius: 0)
            .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
        )
    }
}

/// Tek uygulama ikonu; hover'da hafif büyür ve arkaplan alır.
private struct AppIconButton: View {
    let item: AppItem
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(nsImage: item.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: DockController.iconSize, height: DockController.iconSize)
                .frame(width: DockController.iconSize + 10, height: DockController.iconSize + 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(hovering ? 0.16 : 0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(hovering ? 0.12 : 0), lineWidth: 0.5)
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(item.name)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
    }
}

/// Altta göze batmayan ayar butonu.
private struct SettingsButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(hovering ? 0.9 : 0.4))
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(.white.opacity(hovering ? 0.15 : 0))
                )
        }
        .buttonStyle(.plain)
        .help("Ayarlar")
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}
