import ArgumentParser
import Hummingbird
import Foundation

struct Serve: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Start the Ibex Inference Server"
    )

    @Option(name: .shortAndLong, help: "Hostname to bind the server to")
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong, help: "Port to bind the server to")
    var port: Int = 8080
    
    @Option(name: .shortAndLong, help: "HuggingFace Model ID or local path (e.g. mlx-community/Llama-3.2-1B-Instruct-4bit)")
    var model: String?
    
    @Option(name: .long, help: "HuggingFace Embedding Model ID (e.g. nomic-ai/nomic-embed-text-v1.5)")
    var embeddingModel: String?

    func run() async throws {
        // Validation: At least one model must be provided
        if model == nil && embeddingModel == nil {
             // If nothing provided, default to the standard chat model for convenience 
             // OR error out. Given the user wants "only run embedding model", defaults might be confusing if they forgot valid flags.
             // However, CLI tools often have defaults. 
             // Let's stick to: if NO args provided, use default chat model?
             // Or better: make 'model' optional, but if BOTH are nil, print error.
             print("❌ Error: You must provide at least one model.")
             print("  Use --model <id> for chat models")
             print("  Use --embedding-model <id> for embedding models")
             throw ExitCode.validationFailure
        }

        // 1. Initialize ModelActor
        let modelActor = ModelActor()
        let embeddingActor = EmbeddingActor()
        
        // 2. Load Models
        if let modelId = model {
            print("Initializing MLX Inference Server...")
            try await modelActor.loadModel(modelId: modelId)
        }
        
        if let embeddingModelId = embeddingModel {
            print("Initializing MLX Embedding Model...")
            try await embeddingActor.loadModel(modelId: embeddingModelId)
        }
        
        // 3. Setup Router
        let router = Router()
        let v1 = router.group("v1")
        
        if model != nil {
            // Function to create controller (dependency injection)
            let openAIController = OpenAIController(modelActor: modelActor)
            openAIController.addRoutes(to: v1)
        }
        
        if embeddingModel != nil {
            let embeddingController = EmbeddingController(embeddingActor: embeddingActor)
            embeddingController.addRoutes(to: v1)
        }
        
        // Health check
        router.get("/health") { _, _ in "OK" }

        // 4. Start Server
        let app = Application(
            router: router,
            configuration: .init(address: .hostname(hostname, port: port))
        )

        print("🚀 Server started on http://\(hostname):\(port)")
        if model != nil {
            print("👉 OpenAI Compatible Endpoint: http://\(hostname):\(port)/v1/chat/completions")
        }
        if embeddingModel != nil {
            print("👉 Embeddings Endpoint: http://\(hostname):\(port)/v1/embeddings")
        }
        
        try await app.runService()
    }
}
