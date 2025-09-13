//
//  RoomMessagesView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//


import SwiftUI

struct RoomMessagesView: View {
    @ObservedObject var skyway: SkyWayViewModel
    @State private var newMessage: String = ""
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            GradientBackground()
            VStack {
                MessageScrollView(
                    skyway: skyway,
                    isTextFieldFocused: Binding(
                                        get: { isTextFieldFocused },
                                        set: { isTextFieldFocused = $0 }
                                    )
                ).padding(.top)
                HStack {
                    TextField("Type a message...", text: $newMessage)
                        .padding(10)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.leading, 5)
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(newMessage.isEmpty ? Color.gray : .blue)
                            .font(.title2)
                            .padding(.trailing)
                    }
                    .disabled(newMessage.isEmpty)
                }
                .padding([.bottom, .top], 10)
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Messages")
            .background(Color(white: 0.9, opacity: 0.7))
        }
    }
    
    func sendMessage() {
        if !newMessage.isEmpty {
            let messageObject = Message(
                message: newMessage,
                type: "sent",
                timeStamp: Date(),
                sender: skyway.localMember?.name ?? "Anonymous"
            )
            
            if let jsonMessage = skyway.encodeMessageToJSON(message: messageObject) {
                skyway.sendMessage(jsonMessage)
            }
            
            newMessage = ""
        }
    }
}
