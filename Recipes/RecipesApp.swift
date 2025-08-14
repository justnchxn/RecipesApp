import SwiftUI

@main
struct RecipesApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var theme = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(theme)
                .preferredColorScheme(theme.kind.colorScheme)  
                .themedBackground(theme.theme)
        }
    }
}
