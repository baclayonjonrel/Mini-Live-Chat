//
//  ChatViewModel.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//

import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var messages: [MessageResponse] = []
    @Published var isTyping: Bool = false {
        didSet {
            print(">>> ViewModel isTyping changed to", isTyping)
        }
    }


    var currentPeerActive: User?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .messageUpdateNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let action = userInfo["action"] as? String else { return }
                
                if action == "typing" {
                    self.isTyping = true
                } else if action == "notTyping" {
                    self.isTyping = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch messages
    func fetchMessages(threadId: String) {
        guard threadId.isEmpty == false else { return }
        AppUtility.shared.fetchMessages(threadId: threadId) { result in
            switch result {
            case .success(let messages):
                DispatchQueue.main.async {
                    self.messages = messages
                } 
            case .failure(let failure):
                print("error: \(failure)")
            }
        }
    }
    
    // MARK: - Send message
    func sendMessage(text: String, threadId: String, token: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(GlobalConstants.BASE_API_URL)/messages") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": text,
            "threadId": threadId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> MessageResponse in
                guard let httpResp = response as? HTTPURLResponse, 200..<300 ~= httpResp.statusCode else {
                    throw URLError(.badServerResponse)
                }
                let wrapper = try Self.jsonDecoder.decode(MessageWrapper.self, from: data)
                return wrapper.message
            }
            .receive(on: DispatchQueue.main)
            .sink { completionStatus in
                if case let .failure(error) = completionStatus {
                    print("❌ Send message error: \(error)")
                    completion?(false)
                }
            } receiveValue: { [weak self] newMessage in
                self?.messages.append(newMessage)
                completion?(true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update message status
    func updateStatus(messageId: String, status: MessageResponse.Status, token: String) {
        guard let url = URL(string: "\(GlobalConstants.BASE_API_URL)/messages/\(messageId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["status": status.rawValue]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> MessageResponse in
                guard let httpResp = response as? HTTPURLResponse, 200..<300 ~= httpResp.statusCode else {
                    throw URLError(.badServerResponse)
                }
                let wrapper = try Self.jsonDecoder.decode(MessageWrapper.self, from: data)
                return wrapper.message
            }
            .receive(on: DispatchQueue.main)
            .sink { completionStatus in
                if case let .failure(error) = completionStatus {
                    print("❌ Update status error: \(error)")
                }
            } receiveValue: { [weak self] updatedMessage in
                if let idx = self?.messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    self?.messages[idx] = updatedMessage
                }
            }
            .store(in: &cancellables)
    }
    
    func markThreadAsRead(threadId: String) {
        guard let url = URL(string: "\(GlobalConstants.BASE_API_URL)/threads/\(threadId)/read") else { return }
        
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Mark thread read error: \(error)")
                return
            }
            print("✅ Thread marked as read")
        }.resume()
    }

    // MARK: - Reactions
    func addReaction(_ emoji: String, to id: String) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        if !messages[idx].reactions.contains(emoji) {
            messages[idx].reactions.append(emoji)
        } else {
            messages[idx].reactions.removeAll { $0 == emoji } // toggle off
        }
    }
    
    // MARK: - Delete message
    func deleteMessage(id: String) {
        messages.removeAll { $0.id == id }
    }
    
    // MARK: - JSON decoder
    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Wrapper struct (matches backend)
    struct MessageWrapper: Codable {
        let message: MessageResponse
    }
}
