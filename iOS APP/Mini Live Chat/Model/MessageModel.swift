//
//  MessageModel.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/21/25.
//

import Foundation

struct Message: Identifiable, Codable {
    var id = UUID()
    var message: String
    var type: String
    var timeStamp: Date
    var sender: String
    
    init(message: String, type: String, timeStamp: Date, sender: String) {
        self.message = message
        self.type = type
        self.timeStamp = timeStamp
        self.sender = sender
    }
}

