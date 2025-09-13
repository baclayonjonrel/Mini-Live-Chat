//
//  RoomView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/21/25.
//

import SwiftUI
import SkyWayRoom

struct RoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var skyway: SkyWayViewModel
    @State private var showMessages: Bool = false
    @State private var showButton = false
    @State var showConfirmationAlert: Bool = false
    @State var confirmationAlertMessage: String = ""
    @State var showingAlert: Bool = false
    @State var alertMessage: String = ""
    @State private var showBadge: Bool = false
    
    @State private var isMuted = false
    @State private var isVideoOff = false
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var showAINoteSheet = false
    
    var onLeave: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            let cardWidth = max(1, (screenWidth - 30) / 2)
            let cardHeight = max(1, screenHeight * 0.48)
            
            ZStack {
                Color.gray
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
                VStack (spacing: 0) {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                // Background black card
                                Color.black
                                    .cornerRadius(10)
                                    .frame(width: cardWidth, height: cardHeight)

                                let videoSubscriptions = skyway.localSubscriptions.filter { $0.stream is RemoteVideoStream }

                                if videoSubscriptions.isEmpty {
                                    // Show placeholder
                                    Image(systemName: "video.slash.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                } else {
                                    // Show progress while loading
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)

                                    // Video TabView
                                    TabView {
                                        ForEach(videoSubscriptions) { sub in
                                            if let videoStream = sub.stream as? RemoteVideoStream {
                                                RepresentableVideoView(stream: videoStream)
                                                    .cornerRadius(10)
                                                    .frame(width: cardWidth, height: cardHeight)
                                            }
                                        }
                                    }
                                    .tabViewStyle(.page(indexDisplayMode: .never))
                                }
                            }
                            .frame(width: cardWidth, height: cardHeight)
                            
                            
                            ZStack {
                                if isVideoOff {
                                    Color.black
                                        .cornerRadius(10)
                                        .frame(width: cardWidth, height: cardHeight)
                                        .overlay {
                                            Image(systemName: "video.slash.fill") // camera symbol
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40) // adjust size as needed
                                        }
                                } else {
                                    Color.black
                                        .cornerRadius(10)
                                        .frame(width: cardWidth, height: cardHeight)
                                        .overlay {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.5)
                                        }
                                    RepresentableCameraPreviewView()
                                       .cornerRadius(10)
                                       .frame(width: cardWidth, height: cardHeight)
                                       .clipped()
                                }
                            }
                   }
                   .padding(10)
                        
                    }
                    
                    SpeechView(skyWay: skyway)
                        .background(Color.clear)
                }
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        
                        Button(action: {
                            // Generate AI Notes
                            showAINoteSheet = true
                        }) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                                .frame(width: 60, height: 60)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(color: .gray, radius: 4, x: 0, y: 2)
                        }
                        
                        // Mute / Unmute
                        Button(action: {
                            isMuted.toggle()
                            Task { await skyway.toggleAudio() }
                        }) {
                            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                                .frame(width: 60, height: 60)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .shadow(color: .gray, radius: 4, x: 0, y: 2)
                        }
                        
                        // Video On / Off
                        Button(action: {
                            isVideoOff.toggle()
                            Task { await skyway.toggleVideo() }
                        }) {
                            Image(systemName: isVideoOff ? "video.slash.fill" : "video.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                                .frame(width: 60, height: 60)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .shadow(color: .gray, radius: 4, x: 0, y: 2)
                        }
                        
                        // End Call
                        Button(action: {
                            confirmationAlertMessage = "Exit Room?"
                            showConfirmationAlert = true
                        }) {
                            Image(systemName: "phone.down.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(color: .gray, radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                    .background(Color.clear)
                    .opacity(showButton ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showButton)
                }

            }.alert(confirmationAlertMessage, isPresented: $showConfirmationAlert) {
                Button("OK", role: .destructive) {
                    handleLeaveAction()
                }
                Button("Cancel", role: .cancel) {
                    
                }
            }.alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    handleLeaveAction()
                }
            }.sheet(isPresented: $showMessages, onDismiss: {
                showBadge = false
            }) {
                RoomMessagesView(skyway: skyway)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(screenHeight * 0.75)])
            }.onAppear{
                Task {
                    try await skyway.publishStreams(includeDataStream: true)
                    for pub in skyway.remotePublications {
                        guard let _ = try? await skyway.subscribe(publication: pub) else {
                            return
                        }
                    }
                }
            
                showButtonsForSeconds()
            }.onTapGesture {
                showButtonsForSeconds()
            }.onChange(of: skyway.allMessages.count) { _ in
                if let lastMessage = skyway.allMessages.last, !lastMessage.type.isEmpty {
                    if lastMessage.type != "sent" {
                        showBadge = true
                        showButtonsForSeconds()
                    } else {
                        showBadge = false
                    }
                }
            }.sheet(isPresented: $showAINoteSheet) {
                        // Your half-sheet content
                AINoteSheetView(skyWay: skyway)
                            .presentationDetents([.medium, .large]) // .medium for half-sheet
                    }
        }
    }
    
    private func showButtonsForSeconds() {
        showButton = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            showButton = false
        }
    }
    
    private func handleLeaveAction() {
        Task {
            if skyway.isJoined {
                try await skyway.leave()
                try await skyway.disposeContext()
            }
        }
        
        onLeave?()
    }
}
//
//#Preview {
//    // Mock ViewModel for previews only
//    class MockSkyWayViewModel: SkyWayViewModel {
//        override init() {
//            super.init()
//            // Fill with dummy data if needed
//            self.allMessages = [
//                ]
//        }
//    }
//
//    let mockSkyway = MockSkyWayViewModel()
//
//    return RoomView(
//        skyway: mockSkyway
//    )
//}

struct AINoteSheetView: View {
    @ObservedObject var skyWay: SkyWayViewModel
    @State var message: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack {
            Text("AI Notes")
                .font(.title)
                .padding()
            Divider()
            
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(1.5)
                    Text("Generating summary...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            } else {
                ScrollView {
                    Text(message)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .onAppear {
            // Collect messages with sender
            let messagesForAI = skyWay.allMessages.map { "\($0.sender): \($0.message)" }
            
            SummaryMaker.shared.summarizeSentences(messagesForAI) { summary in
                isLoading = false
                if let summary = summary {
                    message = summary
                } else {
                    message = "Failed to get summary"
                }
            }
        }
        .padding()
    }
}


struct SpeechView: View {
    @ObservedObject var skyWay: SkyWayViewModel
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 📝 Final transcript bubbles
                        ForEach(skyWay.allMessages.indices, id: \.self) { index in
                            let message = skyWay.allMessages[index]
                            VStack {
                                HStack {
                                    if message.type == "received" {
                                        VStack {
                                            Text(message.message)
                                                .padding(5)
                                                .background(Color.gray.opacity(0.7))
                                                .cornerRadius(8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
//                                            Text(message.sender)
//                                                .padding(.leading)
//                                                .font(.system(size: 8))
//                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    } else {
                                        Spacer()
                                        VStack {
                                            Text(message.message)
                                                .padding(5)
                                                .background(Color.blue.opacity(0.7))
                                                .cornerRadius(8)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
//                                            Text(message.sender)
//                                                .padding(.trailing)
//                                                .font(.system(size: 8))
//                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                            .id(index)
                        }
                        
                        // 👂 Live updating text
                        if !skyWay.newSentence.isEmpty {
                            HStack {
                                Spacer()
                                Text(skyWay.newSentence)
                                    .padding(5)
                                    .italic()
                                    .foregroundColor(.blue)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .id("live") // give it a fixed id
                            }
                        }
                    }
                    .padding()
                }
                // Auto-scroll when transcript changes
                .onChange(of: skyWay.transcript) { _ in
                    if let lastIndex = skyWay.allMessages.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
                // Auto-scroll when live sentence changes
                .onChange(of: skyWay.newSentence) { _ in
                    withAnimation {
                        proxy.scrollTo("live", anchor: .bottom)
                    }
                }
            }
            .background(Color.clear)
            .cornerRadius(10)
            .frame(
                width: UIScreen.main.bounds.width - 20
            )
        }
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(10)
        .frame(
            width: UIScreen.main.bounds.width - 20
        )
    }
}
