//
//  MessageResponse.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import Foundation

struct MessagesWrapper: Codable {
    let messages: [MessageResponse]
}

struct MessageResponse: Codable, Identifiable {
    enum Status: String, Codable, CaseIterable {
        case sending = "Sending"
        case sent    = "Sent"
        case seen    = "Seen"
    }
    
    var id: String
    var senderId: String
    var senderName: String?
    var isMe: Bool
    var text: String
    var timestamp: String
    var status: Status
    var reactions: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case senderId
        case senderName
        case isMe
        case text
        case timestamp
        case status
        case reactions
    }
    
    // ✅ Formatters
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // ✅ Helpers
    var date: Date? {
        Self.isoFormatter.date(from: timestamp)
    }

    var dayString: String {
        guard let date else { return "" }
        return Self.dayFormatter.string(from: date)
    }
    
    var timeString: String {
        guard let date else { return "" }
        return Self.timeFormatter.string(from: date)
    }
    
    // Existing (full) timestamp if needed
    var formattedTimestamp: String {
        guard let date else { return timestamp }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
