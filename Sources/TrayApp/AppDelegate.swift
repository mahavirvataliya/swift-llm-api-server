import AppKit
import SwiftUI

/// App delegate for handling macOS-specific functionality
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start server automatically on launch
        Task {
            await ServerManager.shared.start()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop server on quit
        Task {
            await ServerManager.shared.stop()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running even if all windows are closed (menu bar app)
        return false
    }
}
