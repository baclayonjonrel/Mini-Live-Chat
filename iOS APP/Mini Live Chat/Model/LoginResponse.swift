//
//  LoginResponse.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import Foundation

struct LoginResponse: Codable {
    let result: String
    let token: String?
    let user: User
}

struct User: Codable {
    let _id: String
    let displayName: String
    let email: String
    let createdAt: String?
    
    // Computed property for formatted updatedAt
    var formattedCreatedAt: String? {
        guard let createdAt = createdAt else { return nil }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: createdAt) else { return createdAt }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        return formatter.string(from: date)
    }
}


