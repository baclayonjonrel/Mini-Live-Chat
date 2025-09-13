//
//  AuthManager.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//


import Foundation
import CryptoKit

// MARK: - Auth Manager
class AuthManager {
    static let shared = AuthManager()
    
    private let baseURL = GlobalConstants.BASE_API_URL
    private init() {}
    
    // Signup
    func signup(email: String, password: String, displayName: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let hashedPassword = sha256(password)
        let url = URL(string: "\(baseURL)/auth/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": hashedPassword,
            "displayName": displayName
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            AppUtility.shared.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                        completion(.success(decoded))
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
    
    // Login
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let hashedPassword = sha256(password)
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": hashedPassword
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            AppUtility.shared.validateResponse(data, response, error) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                        completion(.success(decoded))
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
    
    // Hash
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
