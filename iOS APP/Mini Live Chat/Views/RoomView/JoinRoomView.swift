//
//  JoinRoomView.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/22/25.
//

import SwiftUI
import SkyWayRoom

struct JoinRoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var skyway: SkyWayViewModel = .init()
    @ObservedObject var callvm: CallViewModel
    
    var callPeer: User
    var roomName: String
    
    @State private var roomViewIsShown = false
    @State private var isRoomNameValid: Bool = false
    @State private var isUserNameValid: Bool = false
    
    @State var roomNameText: String = ""
    @State var userNameText: String = ""
    
    @State var showingAlert: Bool = false
    @State var alertMessage: String = ""
    @State var loadingStatusMessage: String = "Loading..."
    @State var showLoadingIndicator: Bool = false
    @State var shouldDismissRoomView: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    RepresentableCameraPreviewView()
                        .cornerRadius(5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .padding()
                    IncomingCallView(callerName: callPeer.displayName, callerImage: nil) {
                        userNameText = AppUtility.shared.skyWayValidName(from: callPeer.displayName)
                        roomNameText = roomName
                        onJoinRoomPress()
                    } onDecline: {
                        Task {
                            if skyway.isJoined {
                                try await skyway.leave()
                                try await skyway.disposeContext()
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                        AppUtility.shared.sendCommand(type: .call, target: callPeer, action: CallAction.rejectIncomingCall.rawValue)
                    }

                }
            }.onAppear() {
                setupPreviewCamera()
            }
            .fullScreenCover(isPresented: $roomViewIsShown) {
                RoomView(skyway: skyway) {
                    AppUtility.shared.sendCommand(type: .call, target: callPeer, action: CallAction.disconnectOngoingCall.rawValue)
                    Task {
                        if skyway.isJoined {
                            try await skyway.leave()
                            try await skyway.disposeContext()
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }.alert(alertMessage, isPresented: $showingAlert) {
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
            }.onChange(of: callvm.callStatus) { newStatus in
                switch newStatus {
                case .connected:
//                    DispatchQueue.main.async {
//                        roomViewIsShown = true
//                    }
                    break
                case .disconnected:
                    Task {
                        if skyway.isJoined {
                            try await skyway.leave()
                            try await skyway.disposeContext()
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                case .ringing:
                    //play outgoing ringtone
                    break
                default:
                    break
                }
                
            }
        }
    }
    
    private func onJoinRoomPress() {
        loadingStatusMessage = skyway.roomFindStatus.rawValue.capitalized
        showLoadingIndicator.toggle()
        
        let roomName = roomNameText.trimmingCharacters(in: .whitespaces)
        let userName = userNameText.trimmingCharacters(in: .whitespaces)
        
        Task {
            do {
                try await skyway.setup()
                let room = try await skyway.findRoom(roomName: roomName, roomType: .P2P)
                loadingStatusMessage = skyway.roomJoiningStatus.rawValue.capitalized
                _ = try await skyway.joinRoom(room: room, userName: userName, roomType: .P2P)
                AppUtility.shared.sendCommand(type: .call, target: callPeer, action: CallAction.acceptIncomingCall.rawValue)
                DispatchQueue.main.async {
                    roomViewIsShown = true
                }
            }catch {
                try await skyway.leave()
                try await skyway.disposeContext()
                alertMessage = error.localizedDescription
                shouldDismissRoomView = true
                showingAlert = true
                roomViewIsShown = false
                AppUtility.shared.sendCommand(type: .call, target: callPeer, action: CallAction.rejectIncomingCall.rawValue)
            }
            showLoadingIndicator.toggle()
        }
        
    }
    
    private func setupPreviewCamera() {
        Task {
            do {
                try await skyway.setupCamera()
                try await skyway.publishStreams(includeDataStream: true)
            } catch {
#if !targetEnvironment(simulator)
                alertMessage = error.localizedDescription
                shouldDismissRoomView = true
                showingAlert = true
#endif
            }
        }
    }
}
