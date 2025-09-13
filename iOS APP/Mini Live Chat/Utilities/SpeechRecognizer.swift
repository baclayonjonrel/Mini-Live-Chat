//
//  SpeechRecognizer.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/22/25.
//

import Speech
import AVFoundation

class SpeechRecognizer: NSObject, ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var speechPauseTimer: Timer?
    var lastSegmentEndTime: TimeInterval = 0
    
    @Published var finalSentence: [String] = []
    @Published var newSentence = ""
    
    var lastSavedText: String = ""
    
    var pauseTranscribing: Bool = false

    override init() {
        super.init()
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech auth status: \(status)")
        }
    }

    func startTranscribing() throws {
        // Stop any ongoing recognition before starting a new one
        stopTranscribing()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { result, error in
            guard let result = result else {
                if let error = error as NSError? {
                    let code = error.code
                    let domain = error.domain
                    print("Speech error [\(domain):\(code)] - \(error.localizedDescription)")

                    // Only restart if not "no speech detected"
                    if !(domain == "kAFAssistantErrorDomain" && code == 216) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            try? self.startTranscribing()
                        }
                    } else {
                        print("Stopped: no speech detected (not restarting)")
                    }
                }
                return
            }
            
            if self.pauseTranscribing {
                if self.pauseTranscribing {
                    // While paused, just reset baseline so old text won't leak in later
                    self.lastSavedText = result.bestTranscription.formattedString
                    return
                }
            }

            let fullText = result.bestTranscription.formattedString

            // Compute new text since last saved
            let newTextStartIndex = fullText.index(fullText.startIndex, offsetBy: self.lastSavedText.count, limitedBy: fullText.endIndex) ?? fullText.endIndex
            let newText = String(fullText[newTextStartIndex...])
            
            self.newSentence = newText   // live text

            // Reset timer
            self.speechPauseTimer?.invalidate()
            self.speechPauseTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                if !newText.isEmpty {
                    DispatchQueue.main.async {
                        self.finalSentence.append(newText)  // append only new part
                        self.lastSavedText = fullText       // update last saved
                        self.newSentence = ""               // clear live
                    }
                }
            }
        }
        
        // Remove previous tap if exists
        inputNode.removeTap(onBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopTranscribing() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
