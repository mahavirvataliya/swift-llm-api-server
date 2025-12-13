import SwiftUI
import AppKit

/// Settings view for configuring the Ibex server.
struct SettingsView: View {
    @Environment(ServerManager.self) private var serverManager
    
    @State private var port: String = ""
    @State private var modelDirectory: String = ""
    @State private var showRestartAlert = false
    @State private var hasChanges = false
    
    private let config = IbexConfig.shared
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Server Port") {
                    TextField("Port", text: $port)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: port) { _, _ in
                            hasChanges = true
                        }
                }
                
                LabeledContent("Model Storage") {
                    HStack {
                        TextField("Directory", text: $modelDirectory)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 250)
                            .onChange(of: modelDirectory) { _, _ in
                                hasChanges = true
                            }
                        
                        Button("Browse...") {
                            browseDirectory()
                        }
                    }
                }
                
                Text("Models are stored in: \(modelDirectory)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Server Configuration")
            }
            
            Section {
                HStack {
                    Circle()
                        .fill(serverManager.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(serverManager.statusText)
                }
                
                if serverManager.isRunning {
                    Text("Listening on http://\(config.hostname):\(config.port)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Server Status")
            }
            
            Section {
                HStack {
                    Spacer()
                    
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    
                    Button("Save & Restart") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasChanges)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 300)
        .onAppear {
            loadSettings()
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Restart Now") {
                Task {
                    await serverManager.restart()
                }
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Settings have been saved. The server needs to restart for changes to take effect.")
        }
    }
    
    // MARK: - Actions
    
    private func loadSettings() {
        port = String(config.port)
        modelDirectory = config.modelStorageDirectory
        hasChanges = false
    }
    
    private func saveSettings() {
        // Validate port
        if let portInt = Int(port), portInt > 0 && portInt <= 65535 {
            config.port = portInt
        }
        
        // Validate and save directory
        if !modelDirectory.isEmpty {
            config.modelStorageDirectory = modelDirectory
        }
        
        hasChanges = false
        
        // Show restart prompt if server is running
        if serverManager.isRunning {
            showRestartAlert = true
        }
    }
    
    private func resetToDefaults() {
        config.resetToDefaults()
        loadSettings()
    }
    
    private func browseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: modelDirectory)
        panel.prompt = "Select"
        panel.message = "Choose directory for model storage"
        
        if panel.runModal() == .OK, let url = panel.url {
            modelDirectory = url.path
            hasChanges = true
        }
    }
}

#Preview {
    SettingsView()
        .environment(ServerManager.shared)
}
