import Foundation

/// Central configuration manager for Ibex CLI and Tray app.
/// Provides persistent storage for user preferences using UserDefaults.
@Observable
public final class IbexConfig: Sendable {
    
    // MARK: - Singleton
    
    public static let shared = IbexConfig()
    
    // MARK: - Keys
    
    private enum Keys {
        static let modelStorageDirectory = "ibex.modelStorageDirectory"
        static let port = "ibex.port"
        static let hostname = "ibex.hostname"
    }
    
    // MARK: - Defaults
    
    private static let defaultPort = 8080
    private static let defaultHostname = "127.0.0.1"
    
    /// Default model storage: ~/.ibex/models
    private static var defaultModelStorageDirectory: String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".ibex/models").path
    }
    
    // MARK: - Properties
    
    /// Directory where models are stored. Defaults to ~/.ibex/models
    public var modelStorageDirectory: String {
        get {
            UserDefaults.standard.string(forKey: Keys.modelStorageDirectory) 
                ?? Self.defaultModelStorageDirectory
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.modelStorageDirectory)
        }
    }
    
    /// Server port. Defaults to 8080.
    public var port: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.port)
            return value > 0 ? value : Self.defaultPort
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.port)
        }
    }
    
    /// Server hostname. Defaults to 127.0.0.1.
    public var hostname: String {
        get {
            UserDefaults.standard.string(forKey: Keys.hostname) 
                ?? Self.defaultHostname
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hostname)
        }
    }
    
    // MARK: - Helpers
    
    /// Ensures the model storage directory exists.
    public func ensureModelStorageDirectoryExists() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: modelStorageDirectory) {
            try fileManager.createDirectory(
                atPath: modelStorageDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    /// Returns the full path for a model given its ID.
    /// - Parameter modelId: HuggingFace model ID (e.g., "mlx-community/Llama-3.2-1B-Instruct-4bit")
    /// - Returns: Full path to the model directory
    public func modelPath(for modelId: String) -> String {
        let safeName = modelId.replacingOccurrences(of: "/", with: "--")
        return (modelStorageDirectory as NSString).appendingPathComponent(safeName)
    }
    
    /// Resets all settings to defaults.
    public func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: Keys.modelStorageDirectory)
        UserDefaults.standard.removeObject(forKey: Keys.port)
        UserDefaults.standard.removeObject(forKey: Keys.hostname)
    }
    
    // MARK: - Init
    
    private init() {}
}
