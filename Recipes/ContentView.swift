import SwiftUI

struct ShoppingItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isChecked: Bool
    
    init(id: UUID = UUID(), name: String, isChecked: Bool = false) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
    }
}

final class ShoppingListStore: ObservableObject {
    @Published var items: [ShoppingItem] = [] {
        didSet { save() }
    }
    
    private let storageKey = "shopping_items_v1"
    
    init() { load() }
    
    func addItem(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(ShoppingItem(name: trimmed))
    }
    
    func toggle(_ item: ShoppingItem) {
        guard let idx = items.firstIndex(of: item) else { return }
        items[idx].isChecked.toggle()
    }
    
    func delete(at offsets: IndexSet, in list: [ShoppingItem]) {
        // Map visible indices back to the master list
        let ids = Set(offsets.map { list[$0].id })
        items.removeAll { ids.contains($0.id) }
    }
    
    func completeShopping() {
        withAnimation {
            items.removeAll { $0.isChecked }
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Save failed:", error)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            items = decoded
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: ShoppingListStore
    @State private var newItem = ""
    @FocusState private var textFocused: Bool
    
    var toBuy: [ShoppingItem] { store.items.filter { !$0.isChecked } }
    var checked: [ShoppingItem] { store.items.filter { $0.isChecked } }
    
    var body: some View {
        NavigationStack {
            List {
                if !toBuy.isEmpty {
                    Section("To Buy") {
                        ForEach(toBuy) { item in
                            Row(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { store.toggle(item) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        store.delete(at: IndexSet(integer: toBuy.firstIndex(of: item)!), in: toBuy)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                if !checked.isEmpty {
                    Section("Checked") {
                        ForEach(checked) { item in
                            Row(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { store.toggle(item) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        store.delete(at: IndexSet(integer: checked.firstIndex(of: item)!), in: checked)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .animation(.default, value: store.items)
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        store.completeShopping()
                    } label: {
                        Label("Complete Shopping", systemImage: "checkmark.seal")
                    }
                    .disabled(!store.items.contains { $0.isChecked })
                    .help("Remove all checked items")
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    TextField("Add ingredient…", text: $newItem)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .submitLabel(.done)
                        .focused($textFocused)
                        .onSubmit(addItem)
                    
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .font(.title3)
                            .accessibilityLabel("Add item")
                    }
                    .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.thinMaterial)
            }
        }
    }
    
    private func addItem() {
        store.addItem(newItem)
        newItem = ""
        textFocused = true
    }
}

private struct Row: View {
    let item: ShoppingItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
                .accessibilityHidden(true)
            
            Text(item.name)
                .strikethrough(item.isChecked, pattern: .solid, color: .primary)
                .foregroundStyle(item.isChecked ? .secondary : .primary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name + (item.isChecked ? ", checked" : ", not checked"))
    }
}

#Preview {
    ContentView()
        .environmentObject(ShoppingListStore())
}
