import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var account: Account?
    @Published var restoring = true
    @Published var selectedTab = 0

    var isSignedIn: Bool { account != nil }

    init() {
        NotificationCenter.default.addObserver(forName: .ftsSessionExpired, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.account = nil }
        }
    }

    func restore() async {
        guard Keychain.readToken() != nil else { restoring = false; return }
        do {
            account = try await APIClient.shared.me()
        } catch {
            Keychain.clearToken()
            account = nil
        }
        restoring = false
    }

    func signIn(_ auth: AuthResponse) {
        Keychain.saveToken(auth.token)
        account = auth.account
        restoring = false
    }

    func refreshAccount() async {
        if let a = try? await APIClient.shared.me() { account = a }
    }

    func signOut() async {
        await APIClient.shared.logout()
        Keychain.clearToken()
        account = nil
    }

    func accountDeleted() {
        Keychain.clearToken()
        account = nil
    }
}

@main
struct FeedToSoldApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .tint(Color("AccentColor"))
                .task { await state.restore() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        if state.restoring {
            ZStack {
                Color(red: 0.980, green: 0.976, blue: 0.961).ignoresSafeArea()
                ProgressView("Opening FeedToSold…")
            }
        } else if state.isSignedIn {
            MainTabs()
        } else {
            AuthView()
        }
    }
}
