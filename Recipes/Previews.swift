import SwiftUI

// Seed data for previews
extension AppStore {
    static func preview() -> AppStore {
        let s = AppStore()
        s.shoppingItems = [
            ShoppingItem(name: "Apples", quantity: 2),
            ShoppingItem(name: "Milk", quantity: 1, isChecked: true),
            ShoppingItem(name: "Pasta", quantity: 3)
        ]
        s.kitchenItems = [
            KitchenItem(name: "Eggs", quantity: 6),
            KitchenItem(name: "Flour", quantity: 1)
        ]
        s.recipes = [
            Recipe(name: "Spaghetti", ingredients: [
                RecipeIngredient(name: "Pasta", quantity: 1),
                RecipeIngredient(name: "Tomato Sauce", quantity: 2)
            ]),
            Recipe(name: "Omelette", ingredients: [
                RecipeIngredient(name: "Eggs", quantity: 3),
                RecipeIngredient(name: "Milk", quantity: 1)
            ])
        ]
        return s
    }
}

// Intial Previews

#Preview("Root • Citrus", traits: .portrait) {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .citrus
    return RootView()
        .environmentObject(store)
        .environmentObject(theme)
        .preferredColorScheme(.light)
        .themedBackground(theme.theme)
}
#Preview("Root • Matcha", traits: .portrait) {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .matcha
    return RootView()
        .environmentObject(store)
        .environmentObject(theme)
        .preferredColorScheme(.light)
        .themedBackground(theme.theme)
}
#Preview("Root • Neon", traits: .portrait) {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .neon
    return RootView()
        .environmentObject(store)
        .environmentObject(theme)
        .preferredColorScheme(.dark)
        .themedBackground(theme.theme)
}

#Preview("Root • Sunset") {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .sunset
    return RootView()
        .environmentObject(store)
        .environmentObject(theme)
        .preferredColorScheme(theme.kind.colorScheme)
        .themedBackground(theme.theme)
}

#Preview("Root • Ocean") {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .ocean
    return RootView()
        .environmentObject(store)
        .environmentObject(theme)
        .preferredColorScheme(theme.kind.colorScheme)
        .themedBackground(theme.theme)
}


// Individual Previews

#Preview("Shopping • Neon") {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .neon
    return NavigationStack {
        ShoppingView()
            .navigationTitle("Shopping")
    }
    .environmentObject(store)
    .environmentObject(theme)
    .preferredColorScheme(.dark)
    .themedBackground(theme.theme)
}

#Preview("Kitchen • Matcha") {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .matcha
    return NavigationStack {
        KitchenView()
            .navigationTitle("Kitchen")
    }
    .environmentObject(store)
    .environmentObject(theme)
    .preferredColorScheme(.light)
    .themedBackground(theme.theme)
}

#Preview("Recipes • Citrus") {
    let store = AppStore.preview()
    let theme = ThemeManager(); theme.kind = .citrus
    return NavigationStack {
        RecipesView()
            .navigationTitle("Recipes")
    }
    .environmentObject(store)
    .environmentObject(theme)
    .preferredColorScheme(.light)
    .themedBackground(theme.theme)
}

#Preview("Theme Picker") {
    let theme = ThemeManager()
    return ThemePickerSheet()
        .environmentObject(theme)
}
