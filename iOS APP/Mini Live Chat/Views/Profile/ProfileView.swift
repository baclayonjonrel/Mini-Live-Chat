//
//  ProfileView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//


import SwiftUI

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    let user: User
    var onDismiss: (() -> Void)?
    @State private var profileImage: Image? = nil

    var body: some View {
        VStack(spacing: 20) {
            Color.clear
                .frame(height: 40)
            ZStack(alignment: .bottomTrailing) {
                // Profile photo or placeholder
                if let image = profileImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(user.displayName.prefix(1))
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                        )
                }

                // Add photo button
                Button(action: {
                    print("Add/change photo tapped")
                    // Implement photo picker here
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .font(.title)
                }
                .offset(x: -10, y: 5)
            }

            // User info
            VStack(spacing: 8) {
                Text(user.displayName)
                    .font(.title2)
                    .bold()
                Text(user.email)
                    .foregroundColor(.gray)
                    .font(.subheadline)

                if let created = user.formattedCreatedAt {
                    Text("Joined: \(created)")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
            .padding(.top, 40)

            Spacer()
            Button("Logout") {
                UserDefaults.standard.removeObject(forKey: "loginToken")
                AppUtility.shared.currentUser = nil
                presentationMode.wrappedValue.dismiss()
                onDismiss?()
            }
        }
        .padding()
        .navigationTitle("Profile")
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(_id: "1", displayName: "John Doe", email: "john@example.com", createdAt: "2025-08-28")
        NavigationStack {
            ProfileView(user: user)
        }
    }
}
