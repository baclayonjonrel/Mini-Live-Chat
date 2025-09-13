//
//  MessagesView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/21/25.
//

import SwiftUI

// MARK: - Root Chat View
struct ChatMessagesView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: ChatViewModel
    @State private var typingTimer: Timer?
    @ObservedObject var callvm: CallViewModel
    
    @State private var isTyping: Bool = false
    @State private var showCreateRoom: Bool = false
    
    var threadPeer: ThreadResponse?
    private var groupedMessages: [String: [MessageResponse]] {
        Dictionary(grouping: vm.messages) { $0.dayString }
    }
    
    var onDismiss: (() -> Void)?
    
    @State private var messageText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(groupedMessages.keys.sorted(), id: \.self) { date in
                            Text(getDateString(for: date)) // Date header
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 6)
                            
                            ForEach(groupedMessages[date] ?? []) { message in
                                MessageRow(
                                    message: message,
                                    onReact: { emoji in vm.addReaction(emoji, to: message.id) },
                                    onDelete: { vm.deleteMessage(id: message.id) }
                                )
                                .id(message.id)
                                .padding(.horizontal, 12)
                            }
                        }
                        
                        // 👇 Typing indicator bubble
                        if vm.isTyping {
                            HStack {
                                TypingBubble()
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                            .id("TypingBubble") // 👈 Give it an ID so we can scroll to it
                        }
                    }
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last?.id {
                        if let currentPeerActive = threadPeer?.participants.first(where: { $0._id != AppUtility.shared.currentUser?._id }) {
                            AppUtility.shared.sendCommand(type: .message, target: currentPeerActive, action: "seen")
                        }
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
                .onAppear(){
                    if let last = vm.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
                .onChange(of: vm.isTyping) { isTyping in
                    if isTyping {
                        withAnimation { proxy.scrollTo("TypingBubble", anchor: .bottom) }
                    }
                }
            }
            .onTapGesture {
                stopTyping()
                UIApplication.shared.endEditing()
            }
            inputBar
        }.onAppear() {
            vm.fetchMessages(threadId: threadPeer?.id ?? "")
            vm.markThreadAsRead(threadId: threadPeer?.id ?? "")
            if let currentPeerActive = threadPeer?.participants.first(where: { $0._id != AppUtility.shared.currentUser?._id }) {
                vm.currentPeerActive = currentPeerActive
            }
        }.onReceive(NotificationCenter.default.publisher(for: .refreshMessagesNotification)) { _ in
            vm.fetchMessages(threadId: threadPeer?.id ?? "")
            vm.markThreadAsRead(threadId: threadPeer?.id ?? "")
        }
        
        .fullScreenCover(isPresented: $showCreateRoom) {
            if let target = threadPeer?.participants.first(where: { $0._id != AppUtility.shared.currentUser?._id }) {
                CreateRoomView(callvm: callvm, callPeer: target)
            }
        }
    }

    private func getDateString(for date: String) -> String {
        guard let firstMessage = groupedMessages[date]?.first,
              let msgDate = firstMessage.date else {
            return date // fallback if no valid message
        }

        if Calendar.current.isDateInToday(msgDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(msgDate) {
            return "Yesterday"
        } else {
            // fallback to the original string
            return date
        }
    }
    
    private var header: some View {
        HStack {
            // Back button
            Image(systemName: "chevron.left")
                .foregroundColor(.gray)
                .onTapGesture {
                    onDismiss?()
                    vm.currentPeerActive = nil
                    presentationMode.wrappedValue.dismiss()
                }

            Spacer()

            Button(action: {
                callvm.initiateCall()
                showCreateRoom = true
            }) {
                Image(systemName: "video.fill")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .overlay(
            VStack(spacing: 2) {
                Text(threadPeer?.threadName ?? "")
                    .font(.headline)
                Text("Online")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        )

        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            // TextField for input
            TextField("Type a message…", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...4) // expandable like Messenger
                .onChange(of: messageText) { newValue in
                    startTyping()
                }
            // Optionally: add emoji / plus button here
            Button {
                // open emoji picker / reactions
            } label: {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20))
            }

            Button {
                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    stopTyping()
                    sendMessage()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(.borderedProminent)
            .tint(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)

        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    func sendMessage() {
        if !messageText.isEmpty {
            AppUtility.shared.sendMessage(text: messageText, threadId: threadPeer?.id) { result in
                switch result {
                case .success(let message):
                    print("Message sent: \(message.text)")
                    if let peer = threadPeer?.participants.first(where: { $0._id != AppUtility.shared.currentUser?._id }) {
                        AppUtility.shared.sendCommand(type: .message, target: peer, text: message.text)
                    }
                    DispatchQueue.main.async {
                        messageText = ""
                        vm.messages.append(message)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func updateMessage(messageId: String) {
        AppUtility.shared.updateMessage(messageId: messageId) { result in
            switch result {
            case .success(let success):
                print("Message \(messageId) updated")
            case .failure(let failure):
                print(failure)
            }
        }
    }
    
    private func startTyping() {
        if !isTyping {
            isTyping = true
            sendTypingCommand(isTyping: true)
        }
        
        // reset existing timer
        typingTimer?.invalidate()
        
        // after 2 seconds of no typing, send notTyping
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            stopTyping()
        }
    }
    
    private func stopTyping() {
        if isTyping {
            isTyping = false
            sendTypingCommand(isTyping: false)
        }
    }
    
    private func sendTypingCommand(isTyping: Bool) {
            if let currentPeerActive = threadPeer?.participants.first(where: { $0._id != AppUtility.shared.currentUser?._id }) {
                AppUtility.shared.sendCommand(
                    type: .message,
                    target: currentPeerActive,
                    action: isTyping ? "typing" : "notTyping"
                )
            }
        }
}

// MARK: - Message Row
struct MessageRow: View {
    var message: MessageResponse
    var onReact: (String) -> Void
    var onDelete: () -> Void

    private let reactionChoices = ["👍","❤️","😂","😮","😢","🙏"]

    var body: some View {
        VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
//            // Sender name
//            HStack {
//                if message.isMe { Spacer() }
//                Text(message.senderName ?? "")
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
//                if !message.isMe { Spacer() }
//            }
//            .padding(.horizontal, 6)

            // Bubble + reactions
            HStack {
                if message.isMe { Spacer(minLength: 40) }

                VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
                    ZStack(alignment: message.isMe ? .topTrailing : .topLeading) {
                        // ✅ Just a rounded rectangle
                        Text(message.text)
                            .foregroundStyle(message.isMe ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(message.isMe ? Color.blue : Color.gray.opacity(0.2))
                            )
                            .contextMenu {
                                Menu("Add Reaction") {
                                    ForEach(reactionChoices, id: \.self) { emoji in
                                        Button(emoji) { onReact(emoji) }
                                    }
                                }
                                Button("Delete", role: .destructive) { onDelete() }
                            }
                            .overlay(
                                    Group {
                                        HStack {
                                            if !message.isMe {
                                                Spacer()
                                            }
                                            if !message.reactions.isEmpty {
                                                HStack(spacing: 4) {
                                                    ForEach(message.reactions, id: \.self) { emoji in
                                                        Text(emoji)
                                                    }
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                                .offset(x: message.isMe ? -6 : 6, y: 22)
                                            }
                                            if message.isMe {
                                                Spacer()
                                            }
                                        }
                                    }
                                )
                    }

                    // Status + time
                    HStack(spacing: 6) {
                        if message.isMe {
                            Text(message.status.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(message.timeString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !message.isMe { Spacer(minLength: 40) }
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.endEditing()
                }
            )
        }
    }
}

// MARK: - Typing Bubble (Messenger-style)
struct TypingBubble: View {
    var isFromMe: Bool = false

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 40) }
            HStack(spacing: 6) {
                TypingDot(delay: 0)
                TypingDot(delay: 0.2)
                TypingDot(delay: 0.4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isFromMe ? Color.blue : Color.gray.opacity(0.2))
            )
            if !isFromMe { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
    }
}


struct TypingDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.4

    var body: some View {
        Circle()
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                        .repeatForever()
                        .delay(delay)
                ) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

//// MARK: - Preview
//struct ChatMessagesView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            ChatMessagesView()
//                .previewDisplayName("Light")
//            ChatMessagesView()
//                .preferredColorScheme(.dark)
//                .previewDisplayName("Dark")
//        }
//    }
//}
