import Foundation
import MLX
import MLXEmbedders
import MLXNN // For MLXArray
import Hub // For HubApi

/// Actor responsible for managing the Embedding model state and performing inference.
public actor EmbeddingActor {
    var modelContainer: ModelContainer?
    
    public init() {}
    
    /// Loads a model from the specified path or HuggingFace ID.
    /// - Parameter modelId: Local path or Registry ID (e.g. "nomic-ai/nomic-embed-text-v1.5")
    public func loadModel(modelId: String) async throws {
        print("Loading embedding model: \(modelId)...")
        
        let config = ModelConfiguration(id: modelId)
        self.modelContainer = try await MLXEmbedders.loadModelContainer(configuration: config)
        
        print("Embedding model loaded successfully.")
    }
    
    /// Generates embeddings for the given input text.
    /// - Parameter input: The text to embed.
    /// - Returns: An array of floats representing the embedding.
    public func embed(input: String) async throws -> [Float] {
        guard let container = self.modelContainer else {
            throw NSError(domain: "EmbeddingActor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // MLXEmbedders performs optimized embedding generation
        return try await container.perform { model, tokenizer, pooler in
            // Encode input
            let tokens = tokenizer.encode(text: input)
            let array = MLXArray(tokens).expandedDimensions(axis: 0) // Batch size 1
            
            // Run model
            let output = model(array, positionIds: nil, tokenTypeIds: nil, attentionMask: nil)
            
            // Pool output (e.g. mean pooling or CLS)
            // MLXEmbedders Pooling module takes EmbeddingModelOutput
            let embedding = pooler(output, mask: nil, normalize: true) 
            
            // Convert to [Float]
            // embedding is [1, D]
            return embedding[0].asArray(Float.self)
        }
    }
}
