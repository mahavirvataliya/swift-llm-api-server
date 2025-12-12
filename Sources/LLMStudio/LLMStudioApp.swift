import SwiftUI
import AppKit

@main
struct LLMStudioApp: App {
    @State private var modelManager = ModelManager()
    
    init() {
        // Activate app and bring window to front (needed for SPM executables)
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelManager)
        }
        .defaultSize(width: 1000, height: 700)
    }
}

struct ContentView: View {
    @Environment(ModelManager.self) private var modelManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ModelListView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag(0)
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(1)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
