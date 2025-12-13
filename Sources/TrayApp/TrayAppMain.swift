import SwiftUI
import AppKit

/// Main entry point for Ibex Tray App.
/// This app runs as a macOS menu bar (tray) application.
@main
struct TrayAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var serverManager = ServerManager.shared
    
    init() {
        // Hide dock icon - we're a menu bar app only
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        // Settings window - opened from menu bar
        Settings {
            SettingsView()
                .environment(serverManager)
        }
        
        // Menu bar item
        MenuBarExtra {
            MenuBarContent()
                .environment(serverManager)
        } label: {
            Image(systemName: serverManager.isRunning ? "brain.fill" : "brain")
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Menu bar dropdown content
struct MenuBarContent: View {
    @Environment(ServerManager.self) private var serverManager
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        Group {
            // Status
            Text(serverManager.statusText)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Start/Stop button
            if serverManager.isRunning {
                Button("Stop Server") {
                    Task {
                        await serverManager.stop()
                    }
                }
            } else {
                Button("Start Server") {
                    Task {
                        await serverManager.start()
                    }
                }
                .disabled(serverManager.isStarting)
            }
            
            Divider()
            
            // Server info when running
            if serverManager.isRunning {
                Text("Port: \(IbexConfig.shared.port)")
                    .foregroundColor(.secondary)
                
                Text("Models load on first request")
                    .foregroundColor(.secondary)
                
                Divider()
            }
            
            // Settings
            Button("Settings...") {
                openSettings()
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            // Quit
            Button("Quit Ibex") {
                Task {
                    await serverManager.stop()
                    NSApplication.shared.terminate(nil)
                }
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
