import SwiftUI

struct ProductsView: View {
    @EnvironmentObject var state: AppState
    @State private var products: [Product] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var editing: Product?
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading products…")
                } else if products.isEmpty {
                    ContentUnavailableView {
                        Label("No products yet", systemImage: "tag")
                    } description: {
                        Text("Add the first product to your storefront. Your sales agent sells from this catalog.")
                    } actions: {
                        Button("Add a product") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if let errorText {
                            Text(errorText).font(.footnote).foregroundStyle(.red)
                        }
                        ForEach(products) { p in
                            Button { editing = p } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(p.name).font(.headline).foregroundStyle(.primary)
                                        Spacer()
                                        if !p.priceLabel.isEmpty {
                                            Text(p.priceLabel)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Color("AccentColor"))
                                        }
                                    }
                                    if !p.blurb.isEmpty {
                                        Text(p.blurb)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                    }
                                }
                            }
                        }
                        .onDelete { idx in Task { await delete(at: idx) } }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Label("Add product", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                ProductEditSheet(product: nil) { newProduct in
                    products.append(newProduct)
                    Task { await state.refreshAccount() }
                }
            }
            .sheet(item: $editing) { p in
                ProductEditSheet(product: p) { updated in
                    if let i = products.firstIndex(where: { $0.id == updated.id }) {
                        products[i] = updated
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            products = try await APIClient.shared.products()
            errorText = nil
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        loading = false
    }

    private func delete(at offsets: IndexSet) async {
        for i in offsets {
            let p = products[i]
            do {
                try await APIClient.shared.deleteProduct(id: p.id)
                products.removeAll { $0.id == p.id }
            } catch {
                errorText = (error as? APIError)?.message ?? error.localizedDescription
            }
        }
        await state.refreshAccount()
    }
}

struct ProductEditSheet: View {
    var product: Product?
    var onSaved: (Product) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var priceText = ""
    @State private var blurb = ""
    @State private var busy = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Name", text: $name)
                    TextField("Blurb — what it is, in one line", text: $blurb, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Price") {
                    TextField("Price in dollars (blank = no set price)", text: $priceText)
                        .keyboardType(.decimalPad)
                    Text("Leave the price blank for priced-by-plan offers like the Performance plan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle(product == nil ? "Add product" : "Edit product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(busy || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let p = product {
                    name = p.name
                    blurb = p.blurb
                    if let c = p.priceCents { priceText = String(format: "%.2f", Double(c) / 100) }
                }
            }
        }
    }

    private func save() async {
        busy = true
        errorText = nil
        let cents: Int?
        let trimmed = priceText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            cents = nil
        } else if let dollars = Double(trimmed), dollars >= 0 {
            cents = Int((dollars * 100).rounded())
        } else {
            errorText = "That price does not read as a dollar amount."
            busy = false
            return
        }
        do {
            let saved: Product
            if var p = product {
                p.name = name.trimmingCharacters(in: .whitespaces)
                p.blurb = blurb.trimmingCharacters(in: .whitespaces)
                p.priceCents = cents
                saved = try await APIClient.shared.updateProduct(p)
            } else {
                saved = try await APIClient.shared.addProduct(
                    name: name.trimmingCharacters(in: .whitespaces),
                    priceCents: cents,
                    blurb: blurb.trimmingCharacters(in: .whitespaces))
            }
            onSaved(saved)
            dismiss()
        } catch {
            errorText = (error as? APIError)?.message ?? error.localizedDescription
        }
        busy = false
    }
}
