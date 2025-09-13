//
//  ComposeMessageView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//

import SwiftUI

struct ComposeMessageView: View {
    @State private var searchQuery: String = ""
    @State private var searchResults: [User] = []
    @State private var selectedRecipients: [User] = []
    @State private var messageText: String = ""
    @State private var showAlert = false
    @State private var errorMessage: String?
    var onDismiss: (() -> Void)?
    
    @State private var textEditorHeight: CGFloat = 35

    var body: some View {
        NavigationStack {
            VStack {
                Divider()
                Spacer()
                VStack(spacing: 16) {
                    // Recipient chips
                    if !selectedRecipients.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Text("To:")
                                    .fontWeight(.semibold)
                                ForEach(selectedRecipients, id: \._id) { recipient in
                                    HStack {
                                        Text(recipient.displayName)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .foregroundColor(.blue)
                                        Button(action: {
                                            // Remove this recipient from the array
                                            selectedRecipients.removeAll { $0._id == recipient._id }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.trailing, 5)
                                    }
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }

                    // Search / Input field
                    TextField("Search recipient...", text: $searchQuery)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .onChange(of: searchQuery) { newValue in
                            searchUsers(query: newValue)
                        }

                    // Search results
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(searchResults, id: \._id) { user in
                                    HStack {
                                        Image(systemName: "person.fill")
                                        Text(user.displayName)
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedRecipients.append(user)
                                        searchResults.removeAll()
                                        searchQuery = "" // clear the search field
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }

                    Spacer()

                    HStack {
                        // Message input
                        ResizableTextEditor(text: $messageText, minHeight: 35, maxHeight: 120) { newHeight in
                            self.textEditorHeight = newHeight
                        }
                        .frame(height: textEditorHeight)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )

                        // Send button
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding(10)
                                .background(selectedRecipients.isEmpty || messageText.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .disabled(selectedRecipients.isEmpty || messageText.isEmpty)
                    }
                }
                .padding()
                .navigationTitle("New Message")
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
                }
            }
            }
        .onDisappear() {
            onDismiss?()
        }
    }

    // MARK: - Actions

    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults.removeAll()
            return
        }

        AppUtility.shared.searchUsers(query: query) { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.searchResults = users
                }
            case .failure(let error):
                print("Search failed: \(error.localizedDescription)")
            }
        }
    }

    func sendMessage() {
        guard !selectedRecipients.isEmpty,
              let currentUserId = AppUtility.shared.currentUser?._id else { return }

        // Get participant IDs: all selected recipients + current user
        let partIds = selectedRecipients.map { $0._id } + [currentUserId]
        
        AppUtility.shared.sendMessage(text: messageText, participantIds: partIds) { result in
            switch result {
            case .success(let message):
                print("Message sent: \(message.text)")
                for peer in selectedRecipients.filter({ $0._id != currentUserId }) {
                    AppUtility.shared.sendCommand(type: .message, target: peer, text: message.text)
                }
                DispatchQueue.main.async {
                    messageText = ""
                    selectedRecipients.removeAll()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ComposeMessageView()
}

