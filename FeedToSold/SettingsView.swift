import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.openURL) private var openURL
    @State private var showDelete = false
    @State private var deletePassword = ""
    @State private var busy = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            List {
                if let a = state.account {
                    Section("Account") {
                        LabeledContent("Store", value: a.storeName)
                        LabeledContent("Email", value: a.email)
                        LabeledContent("Plan", value: a.plan.name)
                        if a.ownerComp {
                            LabeledContent("Owner account", value: "Complimentary — $0.00 due")
                        }
                        LabeledContent("Member since", value: DateFmt.shortDate(a.createdAt))
                    }
                }
                Section("Support & legal") {
                    Button {
                        openURL(URL(string: "mailto:support@feedtosold.com")!)
                    } label: { Label("Email support", systemImage: "envelope") }
                    Button {
                        openURL(URL(string: "https://feedtosold.com/privacy")!)
                    } label: { Label("Privacy Policy", systemImage: "hand.raised") }
                    Button {
                        openURL(URL(string: "https://feedtosold.com/terms")!)
                    } label: { Label("Terms of Service", systemImage: "doc.text") }
                    Button {
                        openURL(URL(string: "https://feedtosold.com/data-deletion")!)
                    } label: { Label("Data deletion", systemImage: "trash") }
                }
                Section {
                    Button(role: .destructive) {
                        Task { await state.signOut() }
                    } label: { Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") }
                    Button(role: .destructive) {
                        showDelete = true
                    } label: { Label("Delete Account", systemImage: "person.crop.circle.badge.xmark") }
                    if let errorText {
                        Text(errorText).font(.footnote).foregroundStyle(.red)
                    }
                } footer: {
                    Text("Deleting your account removes your storefront products, your agent conversations, and your sign-in from FeedToSold's app records. It cannot be undone.")
                }
                Section {
                    Text("FeedToSold for iOS, version 1.0\n© 2026 BuckThem. All rights reserved.\nFeedToSold. Created November 5, 2026.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .alert("Delete your account?", isPresented: $showDelete) {
                SecureField("Your password", text: $deletePassword)
                Button("Cancel", role: .cancel) { deletePassword = "" }
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("Enter your password to confirm. This removes your products and conversations and signs you out everywhere in the app.")
            }
        }
    }

    private func deleteAccount() async {
        busy = true
        errorText = nil
        do {
            try await APIClient.shared.deleteAccount(password: deletePassword)
            deletePassword = ""
            state.accountDeleted()
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        busy = false
    }
}
