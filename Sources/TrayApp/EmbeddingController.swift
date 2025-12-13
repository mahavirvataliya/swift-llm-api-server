import Hummingbird
import Foundation

struct EmbeddingController {
    let embeddingActor: EmbeddingActor

    func addRoutes<Context: RequestContext>(to group: RouterGroup<Context>) {
        group.post("/embeddings", use: createEmbedding)
    }

    @Sendable func createEmbedding<Context: RequestContext>(request: Request, context: Context) async throws -> EmbeddingResponse {
        let embeddingRequest = try await request.decode(as: EmbeddingRequest.self, context: context)
        
        // Input validation
        guard !embeddingRequest.input.isEmpty else {
            throw HTTPError(.badRequest, message: "Input cannot be empty")
        }
        
        // Lazy load model if needed (uses model ID from request)
        if let modelId = embeddingRequest.model {
            try await embeddingActor.loadModelIfNeeded(modelId: modelId)
        }
        
        let embedding = try await embeddingActor.embed(input: embeddingRequest.input)
        
        // Construct response
        // Usage tokens calculation is simplified/omitted as Tokenizer is inside Actor
        // We could return 0 or estimating it if needed. For now 0.
        let usage = EmbeddingResponse.Usage(prompt_tokens: 0, total_tokens: 0)
        
        let data = [
            EmbeddingObject(embedding: embedding, index: 0)
        ]
        
        return EmbeddingResponse(
            data: data,
            model: embeddingRequest.model ?? "unknown",
            usage: usage
        )
    }
}
