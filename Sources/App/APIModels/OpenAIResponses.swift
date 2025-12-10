import Foundation
import Hummingbird

public struct ChatCompletionResponse: Codable, ResponseEncodable {
    public struct Choice: Codable {
        public struct Message: Codable {
            public let role: String
            public let content: String
        }
        
        public let index: Int
        public let message: Message
        public let finish_reason: String?
    }
    
    public struct Usage: Codable {
        public let prompt_tokens: Int
        public let completion_tokens: Int
        public let total_tokens: Int
    }
    
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage?
}

public struct ChatCompletionChunk: Codable {
    public struct Choice: Codable {
        public struct Delta: Codable {
            public let role: String?
            public let content: String?
        }
        
        public let index: Int
        public let delta: Delta
        public let finish_reason: String?
    }
    
    public let id: String
    public let object: String 
    public let created: Int
    public let model: String
    public let choices: [Choice]
}
