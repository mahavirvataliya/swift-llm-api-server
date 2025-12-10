import Foundation
import MLX
import MLXLLM
@preconcurrency import MLXLMCommon

/// Actor responsible for managing the LLM model state and performing inference.
/// This ensures that the model is accessed in a thread-safe manner.
public actor ModelActor {
    private var modelContainer: ModelContainer?
    
    public init() {}
    
    /// Loads a model from the specified path or HuggingFace ID.
    /// - Parameter modelId: Local path or Registry ID (e.g. "mlx-community/Llama-3.2-1B-Instruct-4bit")
    public func loadModel(modelId: String) async throws {
        print("Loading model: \(modelId)...")
        
        // Use global loadModelContainer helper from MLXLMCommon
        self.modelContainer = try await MLXLMCommon.loadModelContainer(id: modelId)
        
        print("Model loaded successfully.")
    }
    
    /// Generates text based on the provided messages.
    /// - Parameters:
    ///   - messages: Array of chat messages (OpenAI format)
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Sampling temperature
    /// - Returns: An async stream of generated strings
    public func generate(messages: [[String: String]], maxTokens: Int = 100, temperature: Float = 0.6) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                guard let container = self.modelContainer else {
                    continuation.finish(throwing: NSError(domain: "ModelActor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]))
                    return
                }
                
                // Convert OpenAI messages to MLX formatted messages
                let chatMessages = messages.compactMap { msg -> Chat.Message? in
                    guard let roleRaw = msg["role"], let content = msg["content"] else { return nil }
                    switch roleRaw {
                    case "user": return .user(content)
                    case "assistant": return .assistant(content)
                    case "system": return .system(content)
                    default: return .user(content) // Fallback
                    }
                }
                
                do {
                    // Perform generation within the container's context to ensure thread safety
                    try await container.perform { context in
                        // Prepare input
                        let userInput = UserInput(chat: chatMessages)
                        let input = try await context.processor.prepare(input: userInput)
                        
                        // Generate parameters: check param order in source if fails, but usually memberwise init uses declaration order.
                        // Assuming maxTokens is 'tokenLimit' or similar? MLXLMCommon.GenerateParameters
                        // Looking at headers: GenerateParameters struct likely has default init.
                        // Swift memberwise init requires arg names.
                        // I will try to use the correct argument names.
                        // Common names: temp/temperature, maxTokens/tokenLimit.
                        // Let's assume `temperature` and `maxTokens` are correct but order might be swapped or names different.
                        // Safe bet: GenerateParameters(temperature: temperature, maxTokens: maxTokens) failed with order error.
                        // So maxTokens first?
                        // Or maybe it's `tokenLimit`?
                        // Let's retry with corrected order based on error "argument 'maxTokens' must precede argument 'temperature'"
                        // Wait, previous error said: "argument 'maxTokens' must precede argument 'temperature'".
                        // So I wrote `(temperature: ..., maxTokens: ...)` and it wanted `(maxTokens: ..., temperature: ...)`?
                        // My previous code was `GenerateParameters(temperature: temperature, maxTokens: maxTokens)`.
                        // So yes, I should swap them.
                        let params = GenerateParameters(maxTokens: maxTokens, temperature: temperature)
                        
                        // Create a new cache for this request (Stateless for now)
                        // In V2 we might want to implement KV cache reuse if possible, but for OpenAI API calls 
                        // which send full history, we usually start fresh or need advanced prefix caching.
                        let cache = context.model.newCache(parameters: params)
                        
                        // Stream the response
                        let result = try MLXLMCommon.generate(
                            input: input,
                            cache: cache,
                            parameters: params,
                            context: context
                        )
                        
                        for await item in result {
                            if let chunk = item.chunk {
                                continuation.yield(chunk)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
