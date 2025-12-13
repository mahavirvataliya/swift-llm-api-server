import Foundation
import Hummingbird

/// Observable class managing the Hummingbird server lifecycle.
/// Coordinates with IbexConfig for settings and provides server status.
@MainActor
@Observable
public final class ServerManager {
    
    // MARK: - Singleton
    
    public static let shared = ServerManager()
    
    // MARK: - State
    
    public enum Status {
        case stopped
        case starting
        case running
        case stopping
        case error(String)
    }
    
    public private(set) var status: Status = .stopped
    
    // MARK: - Computed Properties
    
    public var isRunning: Bool {
        if case .running = status { return true }
        return false
    }
    
    public var isStarting: Bool {
        if case .starting = status { return true }
        return false
    }
    
    public var statusText: String {
        switch status {
        case .stopped: return "Server Stopped"
        case .starting: return "Starting..."
        case .running: return "Server Running"
        case .stopping: return "Stopping..."
        case .error(let msg): return "Error: \(msg)"
        }
    }
    
    // MARK: - Internal
    
    private var serverTask: Task<Void, Error>?
    private let modelActor = ModelActor()
    private let embeddingActor = EmbeddingActor()
    
    private init() {}
    
    // MARK: - Server Control
    
    /// Start the Hummingbird server without loading any models.
    /// Models will be loaded lazily on first request.
    public func start() async {
        guard case .stopped = status else {
            print("Server already running or in transition")
            return
        }
        
        status = .starting
        
        let config = IbexConfig.shared
        let port = config.port
        let hostname = config.hostname
        
        // Ensure model storage directory exists
        do {
            try config.ensureModelStorageDirectoryExists()
        } catch {
            status = .error("Failed to create model directory: \(error.localizedDescription)")
            return
        }
        
        serverTask = Task.detached { [weak self] in
            guard let self = self else { return }
            
            do {
                // Setup Router
                let router = Router()
                let v1 = router.group("v1")
                
                // Register controllers (they will lazy load models on request)
                let openAIController = OpenAIController(modelActor: await self.modelActor)
                openAIController.addRoutes(to: v1)
                
                let embeddingController = EmbeddingController(embeddingActor: await self.embeddingActor)
                embeddingController.addRoutes(to: v1)
                
                // Health check
                router.get("/health") { _, _ in "OK" }
                
                // Create application
                let app = Application(
                    router: router,
                    configuration: .init(address: .hostname(hostname, port: port))
                )
                
                await MainActor.run {
                    self.status = .running
                }
                
                print("🚀 Ibex Tray Server started on http://\(hostname):\(port)")
                print("👉 Models will load on first request (lazy loading)")
                print("👉 OpenAI Compatible: http://\(hostname):\(port)/v1/chat/completions")
                print("👉 Embeddings: http://\(hostname):\(port)/v1/embeddings")
                
                // Run server (blocks until shutdown)
                try await app.runService()
                
            } catch {
                await MainActor.run {
                    self.status = .error(error.localizedDescription)
                }
                print("❌ Server error: \(error)")
            }
        }
    }
    
    /// Stop the running server.
    public func stop() async {
        guard case .running = status else {
            print("Server not running")
            return
        }
        
        status = .stopping
        
        // Cancel the server task
        serverTask?.cancel()
        serverTask = nil
        
        status = .stopped
        print("🛑 Server stopped")
    }
    
    /// Restart the server (stop then start).
    public func restart() async {
        await stop()
        try? await Task.sleep(nanoseconds: 500_000_000) // Give it 500ms
        await start()
    }
}
