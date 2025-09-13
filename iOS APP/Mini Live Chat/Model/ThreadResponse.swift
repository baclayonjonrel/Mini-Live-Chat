//
//  ThreadResponse.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import Foundation

struct ThreadResponse: Codable {
    let id: String
    let participants: [User]
    let threadName: String
    let lastMessage: MessageResponse?
    let updatedAt: String
    let unreadCount: Int?
    let hasUnread: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants
        case threadName
        case lastMessage
        case updatedAt
        case hasUnread
        case unreadCount
    }
    
    // Computed property for formatted updatedAt
    var formattedUpdatedAt: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: updatedAt) else { return updatedAt }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        return formatter.string(from: date)
    }
}
