import SwiftUI

struct ShoppingItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var quantity: Int
    var isChecked: Bool
    init(id: UUID = UUID(), name: String, quantity: Int = 1, isChecked: Bool = false) {
        self.id = id; self.name = name; self.quantity = quantity; self.isChecked = isChecked
    }
}
struct KitchenItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var quantity: Int
    init(id: UUID = UUID(), name: String, quantity: Int = 1) {
        self.id = id; self.name = name; self.quantity = quantity
    }
}
struct RecipeIngredient: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var quantity: Int
    init(id: UUID = UUID(), name: String, quantity: Int = 1) {
        self.id = id; self.name = name; self.quantity = quantity
    }
}
struct Recipe: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var ingredients: [RecipeIngredient]
    init(id: UUID = UUID(), name: String, ingredients: [RecipeIngredient] = []) {
        self.id = id; self.name = name; self.ingredients = ingredients
    }
}


final class AppStore: ObservableObject {
    @Published var shoppingItems: [ShoppingItem] = [] { didSet { save() } }
    @Published var kitchenItems:  [KitchenItem]  = [] { didSet { save() } }
    @Published var recipes:       [Recipe]       = [] { didSet { save() } }
    
    private let shoppingKey = "recipesapp.shopping.v2"
    private let kitchenKey  = "recipesapp.kitchen.v1"
    private let recipesKey  = "recipesapp.recipes.v2"
    
    init() { load() }
    
    // Shopping
    func addShoppingItem(_ name: String, qty: Int = 1) { addOrIncrementShopping(name, qty: qty) }
    func toggle(_ item: ShoppingItem) { if let i = shoppingItems.firstIndex(of: item) { shoppingItems[i].isChecked.toggle() } }
    func deleteShopping(at offsets: IndexSet, in list: [ShoppingItem]) {
        let ids = Set(offsets.map { list[$0].id }); shoppingItems.removeAll { ids.contains($0.id) }
    }
    func completeShopping() {
        let purchased = shoppingItems.filter { $0.isChecked }
        for p in purchased { addToKitchen(p.name, qty: p.quantity) }
        withAnimation { shoppingItems.removeAll { $0.isChecked } }
    }
    private func addOrIncrementShopping(_ name: String, qty: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, qty > 0 else { return }
        let key = normalized(trimmed)
        if let i = shoppingItems.firstIndex(where: { normalized($0.name) == key }) {
            shoppingItems[i].quantity += qty
        } else {
            shoppingItems.append(ShoppingItem(name: trimmed, quantity: qty))
        }
    }
    
    // Kitchen
    func addToKitchen(_ name: String, qty: Int = 1) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, qty != 0 else { return }
        let key = normalized(trimmed)
        if let i = kitchenItems.firstIndex(where: { normalized($0.name) == key }) {
            var q = kitchenItems[i].quantity + qty; if q < 0 { q = 0 }
            kitchenItems[i].quantity = q
            if q == 0 { kitchenItems.remove(at: i) }
        } else if qty > 0 {
            kitchenItems.append(KitchenItem(name: trimmed, quantity: qty))
        }
    }
    func deleteKitchen(at offsets: IndexSet) { kitchenItems.remove(atOffsets: offsets) }
    
    // Recipes
    @discardableResult func addRecipe(name: String) -> Recipe {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = Recipe(name: trimmed); if !trimmed.isEmpty { recipes.append(r) }; return r
    }
    func deleteRecipe(at offsets: IndexSet) { recipes.remove(atOffsets: offsets) }
    func addIngredient(_ name: String, qty: Int, to recipeID: UUID) {
        let ing = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ing.isEmpty, qty > 0, let i = recipes.firstIndex(where: { $0.id == recipeID }) else { return }
        recipes[i].ingredients.append(RecipeIngredient(name: ing, quantity: qty))
    }
    func deleteIngredient(at offsets: IndexSet, from recipeID: UUID) {
        guard let i = recipes.firstIndex(where: { $0.id == recipeID }) else { return }
        recipes[i].ingredients.remove(atOffsets: offsets)
    }
    
    private func kitchenQty(for name: String) -> Int {
        let key = normalized(name); return kitchenItems.filter { normalized($0.name) == key }.map { $0.quantity }.reduce(0, +)
    }
    private func shoppingQty(for name: String) -> Int {
        let key = normalized(name); return shoppingItems.filter { normalized($0.name) == key }.map { $0.quantity }.reduce(0, +)
    }
    @discardableResult
    func addMissingIngredientsToShopping(from recipeID: UUID) -> [(String, Int)] {
        guard let recipe = recipes.first(where: { $0.id == recipeID }) else { return [] }
        var added: [String: Int] = [:]
        for ing in recipe.ingredients {
            let needed = max(ing.quantity - kitchenQty(for: ing.name) - shoppingQty(for: ing.name), 0)
            if needed > 0 {
                addOrIncrementShopping(ing.name, qty: needed)
                added[normalized(ing.name), default: 0] += needed
            }
        }
        return recipe.ingredients.reduce(into: [(String, Int)]()) { result, ing in
            let key = normalized(ing.name)
            if let qty = added[key], !result.contains(where: { normalized($0.0) == key }) {
                result.append((ing.name, qty))
            }
        }
    }
    
    private func save() {
        do {
            let enc = JSONEncoder()
            UserDefaults.standard.set(try enc.encode(shoppingItems), forKey: shoppingKey)
            UserDefaults.standard.set(try enc.encode(kitchenItems),  forKey: kitchenKey)
            UserDefaults.standard.set(try enc.encode(recipes),       forKey: recipesKey)
        } catch { print("Save failed:", error) }
    }
    private func load() {
        let dec = JSONDecoder()
        if let d = UserDefaults.standard.data(forKey: shoppingKey),
           let v = try? dec.decode([ShoppingItem].self, from: d) { shoppingItems = v }
        if let d = UserDefaults.standard.data(forKey: kitchenKey),
           let v = try? dec.decode([KitchenItem].self, from: d) { kitchenItems = v }
        if let d = UserDefaults.standard.data(forKey: recipesKey),
           let v = try? dec.decode([Recipe].self, from: d) { recipes = v }
    }
    fileprivate func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}


struct RootView: View {
    @EnvironmentObject var theme: ThemeManager
    var body: some View {
        TabView {
            ShoppingView()
                .tabItem { Label("Shopping", systemImage: "cart") }
            KitchenView()
                .tabItem { Label("Kitchen", systemImage: "takeoutbag.and.cup.and.straw") }
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
        }
        .tint(theme.theme.accent)
    }
}


struct ThemeToolbarButton: View {
    @State private var showTheme = false
    var body: some View {
        Button { showTheme = true } label: {
            Image(systemName: "paintpalette")
        }
        .accessibilityLabel("Theme")
        .sheet(isPresented: $showTheme) { ThemePickerSheet() }
    }
}

// Shopping View

struct ShoppingView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var theme: ThemeManager
    @State private var newItem = ""
    @State private var addQty: Int = 1
    @FocusState private var focused: Bool
    
    var toBuy: [ShoppingItem] { store.shoppingItems.filter { !$0.isChecked } }
    var checked: [ShoppingItem] { store.shoppingItems.filter {  $0.isChecked } }
    private var trimmedName: String { newItem.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    var body: some View {
        NavigationStack {
            List {
                if toBuy.isEmpty && checked.isEmpty {
                    EmptyState(icon: "cart", title: "Your shopping list is empty")
                        .listRowBackground(theme.theme.card)
                } else {
                    if !toBuy.isEmpty {
                        Section("To Buy") {
                            ForEach(toBuy) { item in
                                ShoppingRow(item: item, t: theme.theme)
                                    .contentShape(Rectangle())
                                    .onTapGesture { withAnimation { store.toggle(item) } }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            store.deleteShopping(at: IndexSet(integer: toBuy.firstIndex(of: item)!), in: toBuy)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .listRowBackground(theme.theme.card)
                            }
                        }
                    }
                    if !checked.isEmpty {
                        Section("Checked") {
                            ForEach(checked) { item in
                                ShoppingRow(item: item, t: theme.theme)
                                    .contentShape(Rectangle())
                                    .onTapGesture { withAnimation { store.toggle(item) } }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            store.deleteShopping(at: IndexSet(integer: checked.firstIndex(of: item)!), in: checked)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .listRowBackground(theme.theme.card)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listUsesTheme(theme.theme)
            .navigationTitle("Shopping")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { store.completeShopping() } label: { Image(systemName: "cart") }
                        .accessibilityLabel("Complete Shopping")
                        .disabled(!store.shoppingItems.contains { $0.isChecked })
                }
                ToolbarItem(placement: .navigationBarLeading) { ThemeToolbarButton() }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    TextField("Add item…", text: $newItem)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focused)
                        .onSubmit(add)
                        .padding(.horizontal, 10).padding(.vertical, 10)
                        .background(theme.theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    if !trimmedName.isEmpty {
                        QtyChip(n: addQty, t: theme.theme)
                    }
                    
                    Stepper(value: $addQty, in: 1...99) { Text("\(addQty)") }
                        .labelsHidden().frame(maxWidth: 70)
                    Button(action: add) {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                    .disabled(trimmedName.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }
    private func add() {
        store.addShoppingItem(trimmedName, qty: addQty)
        newItem = ""; addQty = 1; focused = true
    }
}

private struct ShoppingRow: View {
    let item: ShoppingItem
    let t: AppTheme
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
            Text(item.name)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? t.subtext : t.text)
            Spacer()
            Text("x\(item.quantity)").monospacedDigit()
                .foregroundStyle(t.text)
        }
        .padding(.vertical, 6)
    }
}

// Kitchen View

struct KitchenView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var theme: ThemeManager
    @State private var newItem = ""
    @State private var qty: Int = 1
    @FocusState private var focused: Bool
    
    private func bindingForQuantity(item: KitchenItem) -> Binding<Int> {
        Binding(
            get: { item.quantity },
            set: { newValue in
                let delta = newValue - item.quantity
                store.addToKitchen(item.name, qty: delta)
            }
        )
    }
    
    private var trimmedName: String { newItem.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    var body: some View {
        NavigationStack {
            List {
                if store.kitchenItems.isEmpty {
                    EmptyState(icon: "takeoutbag.and.cup.and.straw", title: "No items yet",
                               subtitle: "Complete your shopping to move items here, or add them below.")
                        .listRowBackground(theme.theme.card)
                } else {
                    Section("Inventory") {
                        ForEach(store.kitchenItems) { item in
                            HStack {
                                Text(item.name).foregroundStyle(theme.theme.text)
                                Spacer()
                                Text("x\(item.quantity)")
                                    .monospacedDigit()
                                    .frame(minWidth: 28, alignment: .trailing)
                                    .foregroundStyle(theme.theme.text)
                                Stepper("", value: bindingForQuantity(item: item), in: 0...999)
                                    .labelsHidden()
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(theme.theme.card)
                        }
                        .onDelete(perform: store.deleteKitchen)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listUsesTheme(theme.theme)
            .navigationTitle("Kitchen")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { ThemeToolbarButton() } }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    TextField("Add to kitchen…", text: $newItem)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focused)
                        .onSubmit(add)
                        .padding(.horizontal, 10).padding(.vertical, 10)
                        .background(theme.theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    if !trimmedName.isEmpty {
                        QtyChip(n: qty, t: theme.theme)
                    }
                    
                    Stepper(value: $qty, in: 1...99) { Text("\(qty)") }
                        .labelsHidden().frame(maxWidth: 70)
                    Button(action: add) {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                    .disabled(trimmedName.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }
    private func add() {
        store.addToKitchen(trimmedName, qty: qty)
        newItem = ""; qty = 1; focused = true
    }
}

// Recipe View

struct RecipesView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var theme: ThemeManager
    @State private var showingAdd = false
    
    var body: some View {
        NavigationStack {
            List {
                if store.recipes.isEmpty {
                    EmptyState(icon: "fork.knife", title: "No recipes yet",
                               subtitle: "Tap + to add your first recipe.")
                        .listRowBackground(theme.theme.card)
                } else {
                    ForEach(store.recipes) { recipe in
                        RecipeRow(recipe: recipe, t: theme.theme)
                            .listRowBackground(theme.theme.card)
                    }
                    .onDelete(perform: store.deleteRecipe)
                }
            }
            .listStyle(.insetGrouped)
            .listUsesTheme(theme.theme)
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { ThemeToolbarButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingAdd) {
                AddRecipeSheet(isPresented: $showingAdd)
            }
        }
    }
}

struct RecipeRow: View {
    @EnvironmentObject var store: AppStore
    let recipe: Recipe
    let t: AppTheme
    var body: some View {
        NavigationLink(value: recipe) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name).font(.headline).foregroundStyle(t.text)
                Text("\(recipe.ingredients.reduce(0) { $0 + $1.quantity }) total items")
                    .font(.subheadline)
                    .foregroundStyle(t.subtext)
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                _ = store.addMissingIngredientsToShopping(from: recipe.id)
            } label: { Label("Add to Shopping", systemImage: "cart.badge.plus") }
            .tint(.blue)
            Button(role: .destructive) {
                if let i = store.recipes.firstIndex(where: { $0.id == recipe.id }) {
                    store.recipes.remove(at: i)
                }
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var theme: ThemeManager
    let recipe: Recipe
    @State private var newIngredient = ""
    @State private var newQty: Int = 1
    @FocusState private var focused: Bool
    
    @State private var showAddedAlert = false
    @State private var lastAddedText = ""
    
    private var current: Recipe {
        store.recipes.first(where: { $0.id == recipe.id }) ?? recipe
    }
    private var trimmedName: String { newIngredient.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    var body: some View {
        List {
            Section("Ingredients") {
                if current.ingredients.isEmpty {
                    Text("No ingredients yet").foregroundStyle(theme.theme.subtext)
                } else {
                    ForEach(current.ingredients) { ing in
                        HStack {
                            Text(ing.name).foregroundStyle(theme.theme.text)
                            Spacer()
                            Text("x\(ing.quantity)").monospacedDigit().foregroundStyle(theme.theme.text)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteIngredient(at: offsets, from: current.id)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listUsesTheme(theme.theme)
        .navigationTitle(current.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let added = store.addMissingIngredientsToShopping(from: current.id)
                    lastAddedText = added.isEmpty
                        ? "All ingredients are already in your Kitchen or Shopping list."
                        : added.map { "\($0.0) x\($0.1)" }.joined(separator: ", ")
                    showAddedAlert = true
                } label: { Image(systemName: "cart.badge.plus") }
                .accessibilityLabel("Add Missing to Shopping")
            }
        }
        .alert("Add to Shopping", isPresented: $showAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(lastAddedText) }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                TextField("Add ingredient…", text: $newIngredient)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(add)
                    .padding(.horizontal, 10).padding(.vertical, 10)
                    .background(theme.theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                if !trimmedName.isEmpty {
                    QtyChip(n: newQty, t: theme.theme)
                }
                
                Stepper(value: $newQty, in: 1...99) { Text("\(newQty)") }
                    .labelsHidden().frame(maxWidth: 70)
                Button(action: add) {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .disabled(trimmedName.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
    private func add() {
        store.addIngredient(trimmedName, qty: newQty, to: current.id)
        newIngredient = ""; newQty = 1; focused = true
    }
}

// Add Recipes

struct AddRecipeSheet: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var theme: ThemeManager
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var scratchIngredient = ""
    @State private var scratchQty: Int = 1
    @State private var scratchList: [RecipeIngredient] = []
    @FocusState private var focused: Bool
    
    private var trimmedName: String { scratchIngredient.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., Spaghetti Bolognese", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Ingredients") {
                    if scratchList.isEmpty {
                        Text("Add each ingredient, one at a time.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(scratchList) { ing in
                            HStack {
                                Text(ing.name)
                                Spacer()
                                Text("x\(ing.quantity)").monospacedDigit()
                            }
                        }
                        .onDelete { offsets in
                            scratchList.remove(atOffsets: offsets)
                        }
                    }
                    HStack {
                        TextField("Add ingredient…", text: $scratchIngredient)
                            .textInputAutocapitalization(.words)
                            .focused($focused)
                            .onSubmit(addIngredient)
                            .padding(.horizontal, 10).padding(.vertical, 10)
                            .background(theme.theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        if !trimmedName.isEmpty {
                            QtyChip(n: scratchQty, t: theme.theme)
                        }
                        
                        Stepper(value: $scratchQty, in: 1...99) { Text("\(scratchQty)") }
                            .labelsHidden().frame(maxWidth: 70)
                        Button(action: addIngredient) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let new = store.addRecipe(name: name)
                        for ing in scratchList { store.addIngredient(ing.name, qty: ing.quantity, to: new.id) }
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    private func addIngredient() {
        let t = trimmedName; guard !t.isEmpty else { return }
        scratchList.append(RecipeIngredient(name: t, quantity: scratchQty))
        scratchIngredient = ""; scratchQty = 1; focused = true
    }
}

// Helpers

struct EmptyState: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle)
            Text(title).font(.headline)
            if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }
}

// Themes

struct ThemePickerSheet: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ThemeKind.allCases) { kind in
                    ThemePreviewRow(kind: kind, selected: theme.kind == kind)
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { theme.kind = kind } }
                }
            }
            .listStyle(.insetGrouped)
            .listUsesTheme(theme.theme)                 
            .navigationTitle("Themes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .themedBackground(theme.theme)
        .preferredColorScheme(theme.kind == .neon ? .dark : .light)
    }
}


struct ThemePreviewRow: View {
    let kind: ThemeKind
    let selected: Bool

    var body: some View {
        let t = kind.theme
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [t.bgTop, t.bgBottom],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? t.accent : .white.opacity(0.12), lineWidth: selected ? 2 : 1))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(kind.emoji)  \(kind.title)")
                        .font(.headline)
                        .foregroundStyle(t.text)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(t.accent)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [t.bgTop, t.bgBottom],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? t.accent : .white.opacity(0.10), lineWidth: selected ? 2 : 1)
        )
        .listRowBackground(Color.clear)
    }
}

