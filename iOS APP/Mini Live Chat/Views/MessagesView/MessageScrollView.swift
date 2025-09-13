//
//  MessageScrollView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/23/25.
//

import SwiftUI

struct MessageScrollView: View {
    var skyway: SkyWayViewModel
    @Binding var isTextFieldFocused: Bool
    
    @State private var isAtBottom = false
    @State private var showNewMessageIndicator = false
    @State private var scrollToBottomTrigger = false // Used to trigger the scroll action

    var body: some View {
        ZStack {
            ScrollView {
                ScrollViewReader { value in
                    ForEach(skyway.allMessages.indices, id: \.self) { index in
                        let message = skyway.allMessages[index]
                        VStack {
                            HStack {
                                if message.type == "received" {
                                    VStack {
                                        Text(message.message)
                                            .padding(5)
                                            .background(Color.gray.opacity(0.7))
                                            .cornerRadius(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(message.sender)
                                            .padding(.leading)
                                            .font(.system(size: 8))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else {
                                    Spacer()
                                    VStack {
                                        Text(message.message)
                                            .padding(5)
                                            .background(Color.blue.opacity(0.7))
                                            .cornerRadius(8)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        Text(message.sender)
                                            .padding(.trailing)
                                            .font(.system(size: 8))
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .id(index)
                    }.onChange(of: skyway.allMessages.count) { _ in
                        if isAtBottom {
                            showNewMessageIndicator = false
                            value.scrollTo(skyway.allMessages.count - 1, anchor: .bottom)
                        } else {
                            let lastMessage = skyway.allMessages.last!
                            if lastMessage.type == "sent" {
                                value.scrollTo(skyway.allMessages.count - 1, anchor: .bottom)
                            } else {
                                showNewMessageIndicator = true
                            }
                        }
                    }.onChange(of: scrollToBottomTrigger) { newValue in
                        if newValue {
                            if let lastIndex = skyway.allMessages.indices.last {
                                value.scrollTo(lastIndex, anchor: .bottom)
                            }
                            scrollToBottomTrigger = false
                        }
                    }
                }
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            let contentHeight = geometry.size.height
                            let scrollViewHeight = UIScreen.main.bounds.height
                            self.isAtBottom = contentHeight <= scrollViewHeight
                        }
                        .onChange(of: geometry.frame(in: .global).maxY) { maxY in
                            let scrollViewHeight = UIScreen.main.bounds.height
                            self.isAtBottom = maxY <= scrollViewHeight
                        }
                })
            }.onChange(of: isAtBottom) { newValue in
                if newValue {
                    showNewMessageIndicator = false
                }
            }

            VStack {
                if showNewMessageIndicator {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            scrollToBottomTrigger = true
                            showNewMessageIndicator = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.white)
                            Text("New Messages")
                                .foregroundColor(.white)
                        }
                        .padding(5)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 5)
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}


