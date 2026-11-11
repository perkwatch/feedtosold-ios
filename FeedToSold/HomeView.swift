import SwiftUI

struct HomeView: View {
    @EnvironmentObject var state: AppState
    @State private var dashboard: Dashboard?
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let a = state.account {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.storeName)
                                .font(.title2.bold())
                            HStack(spacing: 8) {
                                Label(a.plan.name, systemImage: a.ownerComp ? "crown.fill" : "creditcard")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color("AccentColor").opacity(0.12))
                                    .clipShape(Capsule())
                                if a.ownerComp {
                                    Text("Owner account")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(a.plan.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if loading {
                        ProgressView("Loading your store…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else if let d = dashboard {
                        if let s = d.store {
                            Text("Your store at feedtosold.com")
                                .font(.headline)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(title: "Plan page taps", value: "\(s.trialClicks)", sub: planTapSummary(s))
                                StatCard(title: "Paid orders", value: "\(s.paidOrders)", sub: "recorded by the door")
                                StatCard(title: "Sales total", value: String(format: "$%.2f", s.paidTotal), sub: "from completed checkouts")
                                StatCard(title: "Email sign-ups", value: "\(s.emailCaptures)", sub: "follow-up list captures")
                            }
                        }
                        Text("Your merchant home")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Products", value: "\(d.products)", sub: "in your storefront")
                            StatCard(title: "Agent conversations", value: "\(d.conversations)", sub: "with the sales agent")
                        }
                        Button {
                            state.selectedTab = 2
                        } label: {
                            Label("Talk to your sales agent", systemImage: "bubble.left.and.bubble.right.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            state.selectedTab = 1
                        } label: {
                            Label("Manage products", systemImage: "tag.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    } else if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(18)
            }
            .background(Color(red: 0.980, green: 0.976, blue: 0.961))
            .navigationTitle("Home")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func planTapSummary(_ s: StoreStats) -> String {
        let parts = s.trialClicksByPlan.sorted { $0.value > $1.value }
            .map { "\($0.key.capitalized) \($0.value)" }
        return parts.isEmpty ? "plan buttons on the door" : parts.joined(separator: " · ")
    }

    private func load() async {
        do {
            dashboard = try await APIClient.shared.dashboard()
            errorText = nil
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        loading = false
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title2.bold())
            Text(sub)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
    }
}
