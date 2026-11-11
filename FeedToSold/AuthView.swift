import SwiftUI

struct AuthView: View {
    @EnvironmentObject var state: AppState
    @State private var mode: Mode = .signIn
    @State private var storeName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var errorText: String?
    @Environment(\.openURL) private var openURL

    enum Mode: String, CaseIterable { case signIn = "Sign In"; case create = "Create Account" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 36)
                VStack(spacing: 4) {
                    Text("FeedToSold")
                        .font(.largeTitle.bold())
                    Text("The feed that sells.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if mode == .create {
                        TextField("Store name", text: $storeName)
                            .textContentType(.organizationName)
                            .fieldStyle()
                    }
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fieldStyle()
                    SecureField("Password", text: $password)
                        .textContentType(mode == .create ? .newPassword : .password)
                        .fieldStyle()
                }

                if let errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if busy { ProgressView() } else { Text(mode == .signIn ? "Sign In" : "Create Account") }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(busy || email.isEmpty || password.isEmpty || (mode == .create && password.count < 8))

                if mode == .create {
                    Text("Passwords need at least 8 characters. Plans and billing live on the web at feedtosold.com — this app is your merchant home.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 18) {
                    Button("Privacy Policy") { openURL(URL(string: "https://feedtosold.com/privacy")!) }
                    Button("Terms of Service") { openURL(URL(string: "https://feedtosold.com/terms")!) }
                }
                .font(.footnote)
                .padding(.top, 8)

                Text("© 2026 BuckThem. All rights reserved.\nFeedToSold. Created November 5, 2026.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.980, green: 0.976, blue: 0.961))
    }

    private func submit() async {
        busy = true
        errorText = nil
        do {
            let auth: AuthResponse
            if mode == .signIn {
                auth = try await APIClient.shared.login(email: email.trimmingCharacters(in: .whitespaces).lowercased(), password: password)
            } else {
                auth = try await APIClient.shared.register(email: email.trimmingCharacters(in: .whitespaces).lowercased(), password: password, storeName: storeName.trimmingCharacters(in: .whitespaces))
            }
            state.signIn(auth)
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        busy = false
    }
}

private extension View {
    func fieldStyle() -> some View {
        self
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.08)))
    }
}
