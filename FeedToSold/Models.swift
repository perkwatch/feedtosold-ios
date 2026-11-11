import Foundation

// Shapes mirror the door's /api/mobile/* JSON exactly (feedtosold.com).

struct PlanRecord: Codable, Equatable {
    var key: String
    var name: String
    var detail: String
}

struct AccountCounts: Codable, Equatable {
    var products: Int
    var conversations: Int
}

struct Account: Codable, Equatable, Identifiable {
    var id: String
    var email: String
    var storeName: String
    var createdAt: String
    var ownerComp: Bool
    var plan: PlanRecord
    var counts: AccountCounts
}

struct AuthResponse: Codable {
    var ok: Bool
    var token: String
    var account: Account
}

struct AccountResponse: Codable {
    var ok: Bool
    var account: Account
}

struct PlanInfo: Codable, Identifiable {
    var key: String
    var name: String
    var priceMonthly: Int
    var blurb: String
    var cap: String
    var stores: String
    var points: [String]
    var webUrl: String
    var id: String { key }
}

struct PerformanceInfo: Codable {
    var name: String
    var feePct: Int
    var cap: String
    var rules: [String]
}

struct PlansResponse: Codable {
    var ok: Bool
    var trialDays: Int
    var supportEmail: String
    var plans: [PlanInfo]
    var performance: PerformanceInfo?
}

struct Product: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var priceCents: Int?
    var priceLabel: String
    var blurb: String
}

struct ProductsResponse: Codable {
    var ok: Bool
    var products: [Product]
}

struct ProductResponse: Codable {
    var ok: Bool
    var product: Product
}

struct StoreStats: Codable {
    var trialClicks: Int
    var trialClicksByPlan: [String: Int]
    var paidOrders: Int
    var paidTotal: Double
    var currency: String
    var emailCaptures: Int
}

struct Dashboard: Codable {
    var scope: String
    var products: Int
    var conversations: Int
    var store: StoreStats?
}

struct DashboardResponse: Codable {
    var ok: Bool
    var dashboard: Dashboard
}

struct ChatMessage: Codable, Identifiable, Equatable {
    var role: String // "visitor" or "agent"
    var text: String
    var at: String
    var id: String { at + "|" + role + "|" + String(text.hashValue) }
}

struct Conversation: Codable, Identifiable {
    var id: String
    var startedAt: String
    var lastAt: String
    var messages: [ChatMessage]
}

struct ConversationSummary: Codable, Identifiable {
    var id: String
    var startedAt: String
    var lastAt: String
    var messageCount: Int
    var preview: String
}

struct ConversationsResponse: Codable {
    var ok: Bool
    var conversations: [ConversationSummary]
}

struct ConversationResponse: Codable {
    var ok: Bool
    var conversation: Conversation
}

struct ChatResponse: Codable {
    var ok: Bool
    var conversationId: String
    var reply: String
    var links: [String]
    var quick: [String]
}

struct OkResponse: Codable {
    var ok: Bool
}

struct ErrorResponse: Codable {
    var ok: Bool
    var error: String?
}

enum DateFmt {
    static let iso = ISO8601DateFormatter()
    static func shortDate(_ s: String) -> String {
        guard let d = iso.date(from: s) else { return "" }
        return d.formatted(date: .abbreviated, time: .omitted)
    }
    static func shortDateTime(_ s: String) -> String {
        guard let d = iso.date(from: s) else { return "" }
        return d.formatted(date: .abbreviated, time: .shortened)
    }
}
