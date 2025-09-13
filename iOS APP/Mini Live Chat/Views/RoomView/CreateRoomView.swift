//
//  CreateRoomView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/22/25.
//

import SwiftUI
import SkyWayRoom

struct CreateRoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var skyway: SkyWayViewModel = .init()
    @ObservedObject var callvm: CallViewModel
    
    var callPeer: User
    
    @State private var roomViewIsShown = false
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    @State private var shouldDismissRoomView: Bool = false
    
    @State var roomNameText: String = ""
    @State var userNameText: String = ""
    
    var body: some View {
        ZStack {
            // Room
            if roomViewIsShown {
                RoomView(skyway: skyway) {
                    AppUtility.shared.sendCommand(type: .call,
                                                  target: callPeer,
                                                  action: CallAction.disconnectOngoingCall.rawValue)
                    Task {
                        if skyway.isJoined {
                            try await skyway.leave()
                            try await skyway.disposeContext()
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            // Outgoing call screen (only while not connected)
            if callvm.callStatus != .connected {
                OutgoingCallView(calleeName: callPeer.displayName,
                                 calleeImage: nil,
                                 onCancel: {
                    Task {
                        if skyway.isJoined {
                            try await skyway.leave()
                            try await skyway.disposeContext()
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                    AppUtility.shared.sendCommand(type: .call,
                                                  target: callPeer,
                                                  action: CallAction.cancelOutgoingCall.rawValue)
                })
            }
        }
        .onChange(of: callvm.callStatus) { newStatus in
            switch newStatus {
            case .connected:
                // The remote accepted → show room
                roomViewIsShown = true
            case .disconnected:
                Task {
                    if skyway.isJoined {
                        try await skyway.leave()
                        try await skyway.disposeContext()
                    }
                }
                presentationMode.wrappedValue.dismiss()
            default:
                break
            }
        }
        .task {
            // Create room when this view appears
            await createAndJoinRoom()
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                if shouldDismissRoomView {
                    Task {
                        if skyway.isJoined {
                            try await skyway.leave()
                            try await skyway.disposeContext()
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func createAndJoinRoom() async {
        userNameText = AppUtility.shared.skyWayValidName(from: callPeer.displayName)
        let uuid = UUID().uuidString
        roomNameText = "Room\(callPeer._id)_\(AppUtility.shared.currentUser?._id ?? "")_\(uuid)"
        
        do {
            try await skyway.setup()
            let room = try await skyway.createRoom(roomName: roomNameText, roomType: .P2P)
            _ = try await skyway.joinRoom(room: room,
                                          userName: userNameText,
                                          roomType: .P2P)
            try await skyway.setupCamera()
            try await skyway.publishStreams()
            // Notify peer we created the room
            AppUtility.shared.sendCommand(type: .call,
                                          target: callPeer,
                                          action: CallAction.initiateOutgoingCall.rawValue,
                                          text: roomNameText)
            
            // Show RoomView immediately for caller
            await MainActor.run {
                roomViewIsShown = true
            }
        } catch {
            await MainActor.run {
                alertMessage = error.localizedDescription
                shouldDismissRoomView = true
                showingAlert = true
                roomViewIsShown = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
