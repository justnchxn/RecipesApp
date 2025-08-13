import SwiftUI

@main
struct RecipesApp: App {
    @StateObject private var store = ShoppingListStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
