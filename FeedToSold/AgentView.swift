import SwiftUI

struct AgentView: View {
    @State private var conversations: [ConversationSummary] = []
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading conversations…")
                } else {
                    List {
                        Section {
                            NavigationLink {
                                ChatView(conversationId: nil)
                            } label: {
                                Label("New conversation", systemImage: "plus.bubble.fill")
                                    .font(.headline)
                            }
                            Text("This is FeedToSold's own sales agent, live — the same agent that sells on feedtosold.com, answering from the real catalog at real prices.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if let errorText {
                            Text(errorText).font(.footnote).foregroundStyle(.red)
                        }
                        if conversations.isEmpty {
                            Text("No conversations yet. Start one above — every conversation is saved here.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Section("Past conversations") {
                                ForEach(conversations) { c in
                                    NavigationLink {
                                        ChatView(conversationId: c.id)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(c.preview.isEmpty ? "Conversation" : c.preview)
                                                .lineLimit(2)
                                            Text("\(c.messageCount) messages · \(DateFmt.shortDateTime(c.lastAt))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sales Agent")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            conversations = try await APIClient.shared.conversations()
            errorText = nil
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        loading = false
    }
}

struct ChatView: View {
    var conversationId: String?
    @EnvironmentObject var state: AppState
    @State private var convId: String?
    @State private var messages: [ChatMessage] = []
    @State private var quick: [String] = []
    @State private var draft = ""
    @State private var sending = false
    @State private var loading = true
    @State private var errorText: String?
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if loading {
                            ProgressView().frame(maxWidth: .infinity).padding()
                        } else if messages.isEmpty {
                            Text("Ask the agent anything — plan prices, product caps, the free trial, how the Performance plan works. It answers only from the real FeedToSold catalog and never invents prices or results.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        ForEach(messages) { m in
                            MessageBubble(message: m)
                                .id(m.id)
                        }
                        if sending {
                            HStack { ProgressView(); Text("The agent is answering…").font(.footnote).foregroundStyle(.secondary) }
                        }
                        if let errorText {
                            Text(errorText).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    .padding(14)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            if !quick.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quick, id: \.self) { q in
                            Button(q) { draft = q; Task { await send() } }
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color("AccentColor").opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
            }
            HStack(spacing: 10) {
                TextField("Message the agent", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08)))
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(sending || draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(Color(red: 0.980, green: 0.976, blue: 0.961))
        }
        .background(Color(red: 0.980, green: 0.976, blue: 0.961))
        .navigationTitle("Sales Agent")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadExisting() }
    }

    private func loadExisting() async {
        convId = conversationId
        if let id = conversationId {
            do {
                let c = try await APIClient.shared.conversation(id: id)
                messages = c.messages
            } catch {
                errorText = (error as? APIError)?.message ?? error.localizedDescription
            }
        }
        loading = false
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !sending else { return }
        draft = ""
        sending = true
        errorText = nil
        messages.append(ChatMessage(role: "visitor", text: text, at: DateFmt.iso.string(from: Date())))
        do {
            let r = try await APIClient.shared.chat(conversationId: convId, message: text)
            convId = r.conversationId
            messages.append(ChatMessage(role: "agent", text: r.reply, at: DateFmt.iso.string(from: Date())))
            quick = r.quick
            await state.refreshAccount()
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        sending = false
    }
}

struct MessageBubble: View {
    var message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "visitor" { Spacer(minLength: 48) }
            Text(message.text)
                .font(.body)
                .padding(12)
                .background(message.role == "visitor" ? Color("AccentColor").opacity(0.14) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.05)))
            if message.role != "visitor" { Spacer(minLength: 48) }
        }
    }
}
