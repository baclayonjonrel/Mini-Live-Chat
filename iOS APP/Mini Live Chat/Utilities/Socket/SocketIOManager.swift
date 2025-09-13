//
//  SocketIOManager.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import Foundation
import SocketIO
import UIKit

enum CommandType: String, Codable {
    case call
    case message
    case notification
    case update
}

struct Command: Codable {
    let type: CommandType
    let content: String
}

struct CommandPayload: Codable {
    let sender: User
    let user: User
    let action: String?
    let text: String?
}

enum CallAction: String, Codable {
    case initiateOutgoingCall = "initiateoutgoingcall"
    case cancelOutgoingCall   = "canceloutgoingcall"
    case disconnectOngoingCall = "disconnectongoingcall"
    case acceptIncomingCall   = "acceptincomingcall"
    case rejectIncomingCall   = "rejectincomingcall"
}

class SocketIOManager {
    static let shared = SocketIOManager()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    private init() {
        // Replace with your server URL
        let url = URL(string: GlobalConstants.BASE_SOCKET_URL)!
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1) // infinite attempts
        ])
        
        socket = manager.defaultSocket
        
        setupHandlers()
        
        // Reconnect when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        socket.connect()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupHandlers() {
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket.IO connected")
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket.IO disconnected")
        }
        
        socket.on("global command") { data, ack in
            guard let dict = data[0] as? [String: Any],
                  let typeStr = dict["type"] as? String,
                  let content = dict["content"] as? String,
                  let type = CommandType(rawValue: typeStr) else { return }

            if let contentData = content.data(using: .utf8) {
                do {
                    let payload = try JSONDecoder().decode(CommandPayload.self, from: contentData)
                    
                    // Only handle if this command targets the current user
                    if payload.user._id == AppUtility.shared.currentUser?._id {
                        print("Sender: \(payload.sender.displayName), Target: \(payload.user.displayName)")
                        print("Action: \(payload.action ?? "nil"), Text: \(payload.text ?? "nil")")
                        
                        let command = Command(type: type, content: content)
                        self.handleCommand(command)
                    }
                } catch {
                    print("Failed to decode CommandPayload: \(error)")
                }
            }
        }
    }
    
    func send(command: Command) {
        let dict: [String: Any] = [
            "type": command.type.rawValue,
            "content": command.content
        ]
        socket.emit("global command", dict)
    }
    
    @objc private func appDidBecomeActive() {
        if socket.status != .connected {
            print("App became active – reconnecting Socket.IO...")
            socket.connect()
        }
    }
    
    private func handleCommand(_ command: Command) {
        switch command.type {
        case .message:
            if let data = decodeCommand(CommandPayload.self, from: command.content) {
                print("Message received - action: \(data.action ?? "nil"), sender: \(data.sender.displayName), target: \(data.user.displayName)")
                // Only update if the target is the current user
                if data.user._id == AppUtility.shared.currentUser?._id {
                    if let encoded = try? JSONEncoder().encode(data) {
                        NotificationCenter.default.post(
                            name: .messageUpdateNotification,
                            object: nil,
                            userInfo: ["payload": encoded]
                        )
                    }
                }
            } else {
                print("Failed to decode message command")
            }

        case .notification:
            if let data = decodeCommand(CommandPayload.self, from: command.content) {
                print("Notification received - action: \(data.action ?? "nil"), sender: \(data.sender.displayName), target: \(data.user.displayName)")
            } else {
                print("Failed to decode notification command")
            }

        case .update:
            if let data = decodeCommand(CommandPayload.self, from: command.content) {
                print("Update received - action: \(data.action ?? "nil"), sender: \(data.sender.displayName), target: \(data.user.displayName)")
            } else {
                print("Failed to decode update command")
            }

        case .call:
            if let data = decodeCommand(CommandPayload.self, from: command.content) {
                print("Call command received - action: \(data.action ?? "nil"), from: \(data.sender.displayName), to: \(data.user.displayName)")
                
                // Only update if the target is the current user
                if data.user._id == AppUtility.shared.currentUser?._id {
                    if let encoded = try? JSONEncoder().encode(data) {
                        NotificationCenter.default.post(
                            name: .callUpdateNotification,
                            object: nil,
                            userInfo: ["payload": encoded]
                        )
                    }
                }
            } else {
                print("Failed to decode call command")
            }
        }
    }

    /// Generic JSON decoder
    private func decodeCommand<T: Decodable>(_ type: T.Type, from jsonString: String) -> T? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    
}
