//
//  RingerHandler.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/29/25.
//

import AVFoundation
import AudioToolbox

class RingerHandler {
    static let shared = RingerHandler()
    private init() {}
    
    private var outgoingPlayer: AVAudioPlayer?
    var ringTimer: Timer?
    // Play a system sound
    func playIncomingCallSound() {
        // System ringtone sound
        let systemSoundID: SystemSoundID = 1113 // or any system sound ID
        AudioServicesPlaySystemSound(systemSoundID)
        
        // Vibrate the device
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    func startRingtoneLoop() {
        playIncomingCallSound()
        ringTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.playIncomingCallSound()
        }
    }

    func stopRingtoneLoop() {
        ringTimer?.invalidate()
        ringTimer = nil
    }
    
    // MARK: - Outgoing Call
    func startOutgoingTone() {
        guard let url = Bundle.main.url(forResource: "outgoing", withExtension: "mp3") else {
            print("⚠️ Outgoing tone file not found")
            return
        }
        do {
            outgoingPlayer = try AVAudioPlayer(contentsOf: url)
            outgoingPlayer?.numberOfLoops = -1 // loop indefinitely
            outgoingPlayer?.prepareToPlay()
            outgoingPlayer?.play()
        } catch {
            print("❌ Failed to play outgoing sound:", error)
        }
    }

    func stopOutgoingTone() {
        outgoingPlayer?.stop()
        outgoingPlayer = nil
    }
}
