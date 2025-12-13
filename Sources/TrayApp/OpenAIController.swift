
import Hummingbird
import Foundation

struct OpenAIController {
    let modelActor: ModelActor
    
    // Define associated routes
    func addRoutes(to group: RouterGroup<BasicRequestContext>) {
        group.get("/health") { _, _ in "OK" }
        group.post("chat/completions", use: chatCompletions)
    }
    
    @Sendable func chatCompletions(_ request: Request, context: BasicRequestContext) async throws -> Response {
        let chatRequest = try await request.decode(as: ChatCompletionRequest.self, context: context)
        
        let messages = chatRequest.messages.map { ["role": $0.role, "content": $0.content] }
        let maxTokens = chatRequest.max_tokens ?? 100
        let temperature = chatRequest.temperature ?? 0.6
        let stream = chatRequest.stream ?? false
        let modelParams = chatRequest.model
        
        // Lazy load model if needed (uses model ID from request)
        try await modelActor.loadModelIfNeeded(modelId: modelParams)
        
        // Generate UUID for the response
        let id = "chatcmpl-\(UUID().uuidString)"
        let created = Int(Date().timeIntervalSince1970)
        
        if stream {
            // Streaming Response (SSE)
            let asyncStream = await modelActor.generate(messages: messages, maxTokens: maxTokens, temperature: temperature)
            
            return Response(
                status: .ok,
                headers: [
                    .contentType: "text/event-stream",
                    .cacheControl: "no-cache",
                    .connection: "keep-alive"
                ],
                body: .init(asyncSequence: asyncStream.map { chunk -> ByteBuffer in
                    let chunkResponse = ChatCompletionChunk(
                        id: id,
                        object: "chat.completion.chunk",
                        created: created,
                        model: modelParams,
                        choices: [
                            .init(index: 0, delta: .init(role: nil, content: chunk), finish_reason: nil)
                        ]
                    )
                    
                    let data = try! JSONEncoder().encode(chunkResponse) // Simplification: try! safe here as struct is codable
                    var buffer = ByteBuffer()
                    buffer.writeString("data: ")
                    buffer.writeBytes(data)
                    buffer.writeString("\n\n")
                    return buffer
                })
            )
        } else {
            // Non-streaming Response
            var content = ""
            for try await chunk in await modelActor.generate(messages: messages, maxTokens: maxTokens, temperature: temperature) {
                content += chunk
            }
            
            let response = ChatCompletionResponse(
                id: id,
                object: "chat.completion",
                created: created,
                model: modelParams,
                choices: [
                    .init(index: 0, message: .init(role: "assistant", content: content), finish_reason: "stop")
                ],
                usage: nil // Implementation TODO: track usage
            )
            
            // Manual encoding to avoid Protocol conformance ambiguity
            let responseBody = try JSONEncoder().encode(response)
            return Response(status: .ok, body: .init(byteBuffer: ByteBuffer(data: responseBody)))
        }
    }
}
