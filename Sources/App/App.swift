import ArgumentParser
import Hummingbird
import Foundation

@main
struct App: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "Hostname to bind the server to")
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong, help: "Port to bind the server to")
    var port: Int = 8080
    
    @Option(name: .shortAndLong, help: "HuggingFace Model ID or local path (e.g. mlx-community/Llama-3.2-1B-Instruct-4bit)")
    var model: String = "mlx-community/Llama-3.2-1B-Instruct-4bit"

    func run() async throws {
        // 1. Initialize ModelActor
        let modelActor = ModelActor()
        
        // 2. Load Model (Blocking startup until loaded, or we could lazy load)
        // For a dedicated inference server, blocking startup is usually preferred so readiness is real.
        print("Initializing MLX Inference Server...")
        try await modelActor.loadModel(modelId: model)
        
        // 3. Setup Router
        let router = Router()
        
        // Function to create controller (dependency injection)
        let openAIController = OpenAIController(modelActor: modelActor)
        
        // Add routes: prefix with /v1
        let v1 = router.group("v1")
        openAIController.addRoutes(to: v1)
        
        // Health check
        router.get("/health") { _, _ in "OK" }

        // 4. Start Server
        let app = Application(
            router: router,
            configuration: .init(address: .hostname(hostname, port: port))
        )

        print("🚀 Server started on http://\(hostname):\(port)")
        print("👉 OpenAI Compatible Endpoint: http://\(hostname):\(port)/v1/chat/completions")
        
        try await app.runService()
    }
}
