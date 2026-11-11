import SwiftUI

struct MainTabs: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView(selection: $state.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            ProductsView()
                .tabItem { Label("Products", systemImage: "tag.fill") }
                .tag(1)
            AgentView()
                .tabItem { Label("Agent", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(2)
            PlanView()
                .tabItem { Label("Plan", systemImage: "creditcard.fill") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
    }
}
