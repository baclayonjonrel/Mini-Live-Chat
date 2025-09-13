//
//  ChatViewModel 2.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//


import Foundation
import Combine

enum CallStatus: String {
    case initiated        // outgoing call initiated
    case ringing          // incoming call ringing
    case connected        // call accepted/ongoing
    case disconnected     // call ended
    case cancelled        // cancelled before connecting
    case none             // idle / no active call
}

final class CallViewModel: ObservableObject {
    @Published var messages: [MessageResponse] = []
    @Published var callStatus: CallStatus = .none
    @Published var callPeer: User?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Outgoing Calls
    func initiateCall() {
        callStatus = .initiated
    }
    
    func cancelCall() {
        callStatus = .cancelled
    }
    
    func disconnectCall() {
        callStatus = .disconnected
    }
    
    // MARK: - Incoming Calls
    func incomingCall() {
        callStatus = .ringing
        // Optionally: trigger local notification, sound, vibration
    }
    
    func acceptCall() {
        callStatus = .connected
    }
    
    func rejectCall() {
        callStatus = .cancelled
    }
}
