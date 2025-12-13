import Foundation
import Hummingbird

public struct ChatCompletionRequest: Codable {
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
    
    public let model: String
    public let messages: [Message]
    public let stream: Bool?
    public let max_tokens: Int?
    public let temperature: Float?
    
    // Additional params can be added as needed
}
