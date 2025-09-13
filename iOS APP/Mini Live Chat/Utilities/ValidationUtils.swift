//
//  ValidationUtils.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/22/25.
//

import Foundation

class ValidationUtils {
    static let paramRegex = "^(?![*]$)[.A-Za-z0-9%*_-]+$"

    static func validateRoomName(_ name: String) -> Bool {
        return NSPredicate(format: "SELF MATCHES %@", paramRegex).evaluate(with: name)
    }

    static func validateUserName(_ name: String) -> Bool {
        return NSPredicate(format: "SELF MATCHES %@", paramRegex).evaluate(with: name)
    }
}
