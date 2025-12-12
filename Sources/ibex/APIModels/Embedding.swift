import Foundation
import Hummingbird

public struct EmbeddingRequest: Codable {
    public let input: String // Simplified: OpenAI supports string or array, we'll start with string
    public let model: String?
}

public struct EmbeddingObject: Codable {
    public let object: String = "embedding"
    public let embedding: [Float]
    public let index: Int
}

public struct EmbeddingResponse: Codable, ResponseEncodable {
    public let object: String = "list"
    public let data: [EmbeddingObject]
    public let model: String
    public let usage: Usage
    
    public struct Usage: Codable {
        public let prompt_tokens: Int
        public let total_tokens: Int
    }
}
