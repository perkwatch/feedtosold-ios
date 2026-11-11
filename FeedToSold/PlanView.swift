import SwiftUI

struct PlanView: View {
    @EnvironmentObject var state: AppState
    @State private var plans: PlansResponse?
    @State private var loading = true
    @State private var errorText: String?
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading plans…")
                } else if let plans {
                    List {
                        if let a = state.account {
                            Section("Your plan") {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(a.plan.name).font(.headline)
                                    Text(a.plan.detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Billing runs on the web through Stripe — never inside this app. Start or change a plan on the web and it applies to your FeedToSold account.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Section("Subscription plans — every plan starts with a \(plans.trialDays)-day free trial") {
                            ForEach(plans.plans) { p in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(p.name).font(.headline)
                                        Spacer()
                                        Text("$\(p.priceMonthly)/mo").font(.headline).foregroundStyle(Color("AccentColor"))
                                    }
                                    Text(p.blurb).font(.footnote).foregroundStyle(.secondary)
                                    Text("\(p.stores) · \(p.cap)").font(.caption).foregroundStyle(.secondary)
                                    ForEach(p.points, id: \.self) { point in
                                        Label(point, systemImage: "checkmark.circle.fill")
                                            .font(.footnote)
                                    }
                                    Button {
                                        if let url = URL(string: p.webUrl) { openURL(url) }
                                    } label: {
                                        Label("Start the \(plans.trialDays)-day free trial on the web", systemImage: "safari")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .padding(.top, 2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        if let perf = plans.performance {
                            Section("Performance plan") {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(perf.name).font(.headline)
                                        Spacer()
                                        Text("\(perf.feePct)% of proven sales").font(.subheadline.weight(.bold)).foregroundStyle(Color("AccentColor"))
                                    }
                                    Text("No monthly fee. The fee applies only to sales with order-level proof — \(perf.cap).")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    ForEach(perf.rules, id: \.self) { rule in
                                        Text("• " + rule).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Button {
                                        openURL(URL(string: "https://feedtosold.com/")!)
                                    } label: {
                                        Label("See the Performance plan on the web", systemImage: "safari")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .padding(.top, 2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        Section {
                            Text("Questions about billing? Email \(plans.supportEmail) and a human will pick it up.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if let errorText {
                            Text(errorText).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red).padding()
                }
            }
            .navigationTitle("Plan & Billing")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            plans = try await APIClient.shared.plans()
            errorText = nil
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        loading = false
    }
}
