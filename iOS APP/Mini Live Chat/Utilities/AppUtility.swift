//
//  AppUtility.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import Foundation
import UIKit
import AudioToolbox
import SwiftUI

class AppUtility {
    static let shared = AppUtility()
    private init() {}
    
    var currentUser: User?
    
    // MARK: - Search Users
    func searchUsers(query: String, completion: @escaping (Result<[User], Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        guard var urlComponents = URLComponents(string: "\(GlobalConstants.BASE_API_URL)/users/search") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        // ✅ Use 'q' parameter as expected by backend
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Log request
        self.logRequest(request, data: request.httpBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let users = try decoder.decode([User].self, from: data)
                        completion(.success(users))
                    } catch {
                        print("❌ [SEARCH USERS] Decoding error: \(error)")
                        completion(.failure(error))
                    }
                case .failure(let err):
                    print("❌ Request failed: \(err.localizedDescription)")
                    completion(.failure(err))
                }
            }
        }.resume()
    }

    
    // MARK: - Fetch Messages
    func fetchCurrentUser(completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let url = URL(string: "\(GlobalConstants.BASE_API_URL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        self.logRequest(request, data: request.httpBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let messages = try decoder.decode(LoginResponse.self, from: data)
                        completion(.success(messages))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let err):
                    print("❌ Request failed: \(err.localizedDescription)")
                    completion(.failure(err))
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Messages for a Thread
    func fetchMessages(threadId: String, completion: @escaping (Result<[MessageResponse], Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let url = URL(string: "\(GlobalConstants.BASE_API_URL)/messages/\(threadId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        self.logRequest(request, data: request.httpBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let wrapper = try decoder.decode(MessagesWrapper.self, from: data)
                        completion(.success(wrapper.messages))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let err):
                    print("❌ Request failed: \(err.localizedDescription)")
                    completion(.failure(err))
                }
            }
        }.resume()
    }

    // MARK: - Send Message in a Thread or Create Thread if Needed
    func sendMessage(text: String, threadId: String? = nil, participantIds: [String]? = nil, completion: @escaping (Result<MessageResponse, Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let url = URL(string: "\(GlobalConstants.BASE_API_URL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["text": text]
        
        if let threadId = threadId {
            body["threadId"] = threadId
        } else if let participantIds = participantIds, !participantIds.isEmpty {
            body["participantIds"] = participantIds
        } else {
            completion(.failure(NSError(domain: "InvalidParams", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Either threadId or participantIds must be provided"])))
            return
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        self.logRequest(request, data: request.httpBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        // Decode combined response with message and thread
                        let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        if let messageData = responseDict?["message"] {
                            let messageJSON = try JSONSerialization.data(withJSONObject: messageData)
                            let message = try decoder.decode(MessageResponse.self, from: messageJSON)
                            completion(.success(message))
                        } else {
                            completion(.failure(NSError(domain: "InvalidData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message key not found in response"])))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let err):
                    print("❌ Request failed: \(err.localizedDescription)")
                    completion(.failure(err))
                }
            }
        }.resume()
    }

    
    // MARK: - Fetch Threads
    func fetchThreads(completion: @escaping (Result<[ThreadResponse], Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let url = URL(string: "\(GlobalConstants.BASE_API_URL)/threads")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        self.logRequest(request, data: request.httpBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    do {
                        let threads = try JSONDecoder().decode([ThreadResponse].self, from: data)
                        completion(.success(threads))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let err):
                    print("❌ Request failed: \(err.localizedDescription)")
                    completion(.failure(err))
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Thread
    func deleteThread(threadId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        guard let url = URL(string: "\(GlobalConstants.BASE_API_URL)/threads/\(threadId)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "ServerError", code: -1)))
                return
            }
            completion(.success(true))
        }.resume()
    }

    // MARK: - Update Message
    func updateMessage(messageId: String, text: String? = nil, reactions: [String]? = nil, status: String? = nil, completion: @escaping (Result<Message, Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "loginToken") else {
            completion(.failure(NSError(domain: "NoToken", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        guard let url = URL(string: "\(GlobalConstants.BASE_API_URL)/messages/\(messageId)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [:]
        if let text = text { body["text"] = text }
        if let reactions = reactions { body["reactions"] = reactions }
        if let status = status { body["status"] = status }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let message = try decoder.decode(Message.self, from: data)
                completion(.success(message))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

}

// API Helper
extension AppUtility {
    private func logRequest(_ request: URLRequest, data: Data?) {
        print("\n--- 🌐 API REQUEST ---")
        print("➡️ URL: \(request.url?.absoluteString ?? "")")
        print("➡️ Method: \(request.httpMethod ?? "")")
        
        if let headers = request.allHTTPHeaderFields {
            print("➡️ Headers: \(headers)")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("➡️ Body: \(bodyString)")
        }
        
        print("--- END REQUEST ---\n")
    }

    private func logResponse(data: Data?, response: URLResponse?, error: Error?) {
        print("\n--- 📩 API RESPONSE ---")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("⬅️ Status: \(httpResponse.statusCode)")
            print("⬅️ URL: \(httpResponse.url?.absoluteString ?? "")")
        }
        
        if let error = error {
            print("❌ Error: \(error.localizedDescription)")
        }
        
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("⬅️ Body: \(prettyString)")
            } else {
                print("⬅️ Raw Body: \(String(data: data, encoding: .utf8) ?? "nil")")
            }
        }
        
        print("--- END RESPONSE ---\n")
    }

    func validateResponse(
        _ data: Data?,
        _ response: URLResponse?,
        _ error: Error?,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // always logResponse
        logResponse(data: data, response: response, error: error)
        
        if let error = error {
            print("API_Debug: - ❌ Network error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("API_Debug: - ❌ Invalid response (not HTTPURLResponse)")
            completion(.failure(NSError(domain: "InvalidResponse", code: -1)))
            return
        }
        
        guard let data = data else {
            print("API_Debug: - ❌ No data in response")
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }
        
        // ✅ Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            print("API_Debug: - ❌ HTTP \(httpResponse.statusCode) error. Body: \(body)")
            let err = NSError(
                domain: "HTTPError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(body)"]
            )
            completion(.failure(err))
            return
        }
        
        print("API_Debug: - ✅ Success HTTP \(httpResponse.statusCode). Data size: \(data.count) bytes")
        completion(.success(data))
    }
}

extension AppUtility {
    func showInAppNotification(senderName: String, messageText: String) {
        guard let window = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return }

        let notif = InAppNotificationView()
        notif.configure(title: senderName, message: messageText, image: nil) {
            print("Notification tapped!")
        }

        notif.show(in: window)

        // Play sound / vibrate
        AudioServicesPlaySystemSound(SystemSoundID(1007))
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    // MARK: - Create Room View
    func showOutGoingCall(callvm: CallViewModel, callPeer: User) {
        guard let topVC = UIApplication.topViewController() else { return }
        let createRoomView = CreateRoomView(callvm: callvm, callPeer: callPeer)
        let hostingVC = UIHostingController(rootView: createRoomView)
        hostingVC.modalPresentationStyle = .fullScreen
        topVC.present(hostingVC, animated: true, completion: nil)
    }
    
    // MARK: - Join Room View
    func showIncomingCall(callvm: CallViewModel, callPeer: User, roomName: String) {
        guard let topVC = UIApplication.topViewController() else { return }
        let joinRoomView = JoinRoomView(callvm: callvm, callPeer: callPeer, roomName: roomName)
        let hostingVC = UIHostingController(rootView: joinRoomView)
        hostingVC.modalPresentationStyle = .fullScreen
        topVC.present(hostingVC, animated: true, completion: nil)
    }
    
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    static func topViewController(base: UIViewController? = UIApplication.shared
                                        .connectedScenes
                                        .compactMap { $0 as? UIWindowScene }
                                        .flatMap { $0.windows }
                                        .first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
            
            if let nav = base as? UINavigationController {
                return topViewController(base: nav.visibleViewController)
            }
            
            if let tab = base as? UITabBarController {
                if let selected = tab.selectedViewController {
                    return topViewController(base: selected)
                }
            }
            
            if let presented = base?.presentedViewController {
                return topViewController(base: presented)
            }
            
            return base
        }
}


extension AppUtility {
    func sendCommand(
        type: CommandType,
        target: User,
        action: String? = nil,
        text: String? = nil
    ) {
        guard let sender = AppUtility.shared.currentUser else { return }

        let payload = CommandPayload(sender: sender, user: target, action: action, text: text)
        
        let jsonData = try? JSONEncoder().encode(payload)
        let jsonString = String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"
        
        let command = Command(type: type, content: jsonString)
        
        SocketIOManager.shared.send(command: command)
    }
}

extension AppUtility {
    func skyWayValidName(from name: String) -> String {
        // 1. Trim whitespace
        var sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Replace spaces with underscores
        sanitized = sanitized.replacingOccurrences(of: " ", with: "_")
        
        // 3. Keep only allowed characters
        let allowedChars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.%*-_")
        sanitized = String(sanitized.unicodeScalars.filter { allowedChars.contains($0) })
        
        // 4. Ensure it’s not just "*"
        if sanitized == "*" || sanitized.isEmpty {
            sanitized = "User_\(Int(Date().timeIntervalSince1970))"
        }
        
        return sanitized
    }
}
