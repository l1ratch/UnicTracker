import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable {
    case tracker = "Трекер"
    case session = "Сессия"
    case constructor = "Конструктор"
    case archive = "Архив"
    case settings = "Настройки"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .tracker: return "checklist.unchecked"
        case .session: return "graduationcap.fill"
        case .constructor: return "square.grid.2x2.fill"
        case .archive: return "archivebox.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var selectedTab: AppTab = .tracker

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .tracker:
                    MainTrackerView(store: store)
                case .session:
                    SessionTrackerView(store: store)
                case .constructor:
                    ConstructorHubView(store: store)
                case .archive:
                    ArchiveHistoryView(store: store)
                case .settings:
                    SettingsHubView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Floating Liquid Glass Pod TabBar (iOS 26/27 Liquid Interface)
            floatingLiquidTabBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
    }

    // MARK: - Floating Liquid Glass TabBar
    private var floatingLiquidTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                    HapticManager.shared.touchGlass()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(store.theme.preset.primaryAccent.opacity(0.25))
                                    .frame(width: 38, height: 38)
                                    .shadow(color: store.theme.preset.primaryAccent.opacity(0.6), radius: 8)
                            }

                            Image(systemName: tab.iconName)
                                .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? store.theme.preset.primaryAccent : .white.opacity(0.45))
                                .scaleEffect(isSelected ? 1.12 : 1.0)
                        }

                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .liquidGlassPod(cornerRadius: 32)
    }
}
