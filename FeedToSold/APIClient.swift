import Foundation

struct APIError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

/// Client for the FeedToSold door's mobile API (https://feedtosold.com/api/mobile/*).
/// Every screen in the app reads and writes through here — real data from the
/// live service, nothing bundled or faked.
final class APIClient {
    static let shared = APIClient()
    private let base = URL(string: "https://feedtosold.com/api/mobile")!
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg)
    }()
    private let decoder = JSONDecoder()

    var token: String? { Keychain.readToken() }

    private func request<T: Decodable>(_ method: String, _ path: String, body: [String: Any]? = nil, authorized: Bool = true) async throws -> T {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authorized, let t = token {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(message: "No response from FeedToSold. Check your connection and try again.")
        }
        if http.statusCode == 401 && authorized {
            Keychain.clearToken()
            NotificationCenter.default.post(name: .ftsSessionExpired, object: nil)
        }
        if !(200...299).contains(http.statusCode) {
            if let err = try? decoder.decode(ErrorResponse.self, from: data), let msg = err.error {
                throw APIError(message: msg)
            }
            throw APIError(message: "FeedToSold returned an error (\(http.statusCode)). Try again in a moment.")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(message: "FeedToSold sent back something the app could not read. Try again in a moment.")
        }
    }

    // MARK: Auth

    func register(email: String, password: String, storeName: String) async throws -> AuthResponse {
        try await request("POST", "register", body: ["email": email, "password": password, "storeName": storeName], authorized: false)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request("POST", "login", body: ["email": email, "password": password], authorized: false)
    }

    func logout() async {
        let _: OkResponse? = try? await request("POST", "logout", body: [:])
    }

    func me() async throws -> Account {
        let r: AccountResponse = try await request("GET", "me")
        return r.account
    }

    func deleteAccount(password: String) async throws {
        let _: OkResponse = try await request("DELETE", "account", body: ["password": password])
    }

    // MARK: Data

    func plans() async throws -> PlansResponse {
        try await request("GET", "plans", authorized: false)
    }

    func dashboard() async throws -> Dashboard {
        let r: DashboardResponse = try await request("GET", "dashboard")
        return r.dashboard
    }

    func products() async throws -> [Product] {
        let r: ProductsResponse = try await request("GET", "products")
        return r.products
    }

    func addProduct(name: String, priceCents: Int?, blurb: String) async throws -> Product {
        var body: [String: Any] = ["name": name, "blurb": blurb]
        if let priceCents { body["priceCents"] = priceCents } else { body["priceCents"] = NSNull() }
        let r: ProductResponse = try await request("POST", "products", body: body)
        return r.product
    }

    func updateProduct(_ p: Product) async throws -> Product {
        var body: [String: Any] = ["name": p.name, "blurb": p.blurb]
        if let c = p.priceCents { body["priceCents"] = c } else { body["priceCents"] = NSNull() }
        let r: ProductResponse = try await request("PUT", "products/\(p.id)", body: body)
        return r.product
    }

    func deleteProduct(id: String) async throws {
        let _: OkResponse = try await request("DELETE", "products/\(id)")
    }

    func conversations() async throws -> [ConversationSummary] {
        let r: ConversationsResponse = try await request("GET", "conversations")
        return r.conversations
    }

    func conversation(id: String) async throws -> Conversation {
        let r: ConversationResponse = try await request("GET", "conversations/\(id)")
        return r.conversation
    }

    func chat(conversationId: String?, message: String) async throws -> ChatResponse {
        var body: [String: Any] = ["message": message]
        if let conversationId { body["conversationId"] = conversationId }
        return try await request("POST", "chat", body: body)
    }
}

extension Notification.Name {
    static let ftsSessionExpired = Notification.Name("ftsSessionExpired")
}
