import SwiftUI

struct MainTabView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("today", systemImage: "house.fill") }

            NavigationStack {
                MedicationListView()
            }
            .tabItem { Label("meds", systemImage: "pills.fill") }

            NavigationStack {
                HistoryTabView()
            }
            .tabItem { Label("history", systemImage: "calendar") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("settings", systemImage: "gearshape.fill") }
        }
        .tint(theme.primary)
    }
}
