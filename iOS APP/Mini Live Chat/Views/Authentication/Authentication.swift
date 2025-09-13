//
//  Authentication.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import SwiftUI

struct Authentication: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var isSignUpMode = false
    
    var onSuccess: () -> Void = { }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome")
                .font(.largeTitle)
                .bold()
            
            // Email input
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Password input
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Show Name input only in Sign Up mode
            if isSignUpMode {
                TextField("Name", text: $name)
                    .autocapitalization(.words)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    if isSignUpMode {
                        signUp()
                    } else {
                        isSignUpMode = true
                    }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isSignUpMode = false
                    signIn()
                }) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Actions
    
    func signUp() {
        guard isValidEmail(email) else {
            errorMessage = "Invalid email address"
            showAlert = true
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        guard name.count > 0 else {
            errorMessage = "Name is required"
            showAlert = true
            return
        }
        
        AuthManager.shared.signup(email: email, password: password, displayName: name) { result in
            switch result {
            case .success(let user):
                UserDefaults.standard.set(user.token, forKey: "loginToken")
                AppUtility.shared.currentUser = user.user
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                    onSuccess()
                }
                
            case .failure(let error):
                print("Login failed: \(error)")
            }
        }
        
        print("Signing up with email: \(email)")
    }
    
    func signIn() {
        guard isValidEmail(email) else {
            errorMessage = "Invalid email address"
            showAlert = true
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        AuthManager.shared.login(email: email, password: password) { result in
            switch result {
            case .success(let user):
                UserDefaults.standard.set(user.token, forKey: "loginToken")
                AppUtility.shared.currentUser = user.user
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                    onSuccess()
                }
            case .failure(let error):
                print("Login failed: \(error)")
            }
        }
        print("Signing in with email: \(email)")
    }
    
    // MARK: - Helpers
    
    func isValidEmail(_ email: String) -> Bool {
        // Simple regex for email validation
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: email)
    }
}

//struct Authentication_Previews: PreviewProvider {
//    static var previews: some View {
//        Authentication()
//    }
//}
