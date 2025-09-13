//
//  AIResponse.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//

import Foundation

struct AIResponse: Codable {
    let aiText: String
    let raw: RawResponse
}

struct RawResponse: Codable {
    let id: String
    let provider: String
    let model: String
    let object: String
    let created: Int
    let choices: [Choice]
    let system_fingerprint: String?
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finish_reason: String?
        let native_finish_reason: String?
        
        struct Message: Codable {
            let role: String
            let content: String
            let refusal: String?
            let reasoning: String?
        }
    }
    
    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}

// Optional: error response
struct AIErrorResponse: Codable {
    let error: String
}

struct AIUsageResponse: Codable {
    let success: Bool
    let usage: String
}

struct UsageData: Codable {
    let total_tokens: Int?
    let used_tokens: Int?
    let remaining_tokens: Int?
}
