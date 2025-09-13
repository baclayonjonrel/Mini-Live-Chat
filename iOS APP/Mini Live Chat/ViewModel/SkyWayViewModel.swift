//
//  SkyWayViewModel.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/21/25.
//

import SkyWayRoom
import Combine

class SkyWayViewModel: NSObject, ObservableObject, RoomDelegate, RemoteDataStreamDelegate {
    var room: Room?
    var localMember: LocalRoomMember?
    var dataStream: LocalDataStream?
    var isAutoSubscribing: Bool = true
    
    let highEncodeId: String = "high"
    let lowEncodeId: String = "low"
    
    @Published var remotePublications: [RoomPublication] = []
    @Published var localSubscriptions: [RoomSubscription] = []
    @Published var receivedMessage: [String] = []
    @Published var sentMessages: [String] = []
    @Published var allMessages: [Message] = []
    
    @Published var roomCreationStatus: RoomCreationStatus = .notStarted
    @Published var roomJoiningStatus: RoomJoinStatus = .notStarted
    @Published var roomFindStatus: RoomFindStatus = .notStarted
    
    @Published var isVideoEnabled: Bool = true
    @Published var isAudioEnabled: Bool = true
    
    private var videoPublication: RoomPublication?
    private var audioPublication: RoomPublication?
    
    lazy var currentEncoding: String = highEncodeId
    
    @Published var transcript: [String] = []
    @Published var newSentence = ""
    private var speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        // Bind transcript updates
        speechRecognizer.$newSentence
            .receive(on: RunLoop.main)
            .assign(to: &$newSentence)
        speechRecognizer.$finalSentence
            .receive(on: RunLoop.main)
            .sink { [weak self] finalTranscript in
                guard let self = self else { return }
                self.transcript = finalTranscript

                self.onSendMessage(message: finalTranscript.last ?? "")
            }
            .store(in: &cancellables)
    }
    
    var isJoined: Bool {
        return localMember != nil
    }
    
    // MARK: - Setup
    func setup() async throws {
        let opt: ContextOptions = .init()
        opt.logLevel = .trace
        do {
            try await Context.setup(withToken: GlobalConstants.AUTHENTICATION_TOKEN, options: opt)
        } catch {
            print(error)
            throw NSError(domain: "SkywayError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to set up Skyway context: \(error.localizedDescription)"])
        }
    }
    
    func setupCamera() async throws {
        guard let frontCamera = CameraVideoSource.supportedCameras().first(where: { $0.position == .front }) else {
            throw NSError(domain: "SkywayError", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "No front camera found."])
        }
        do {
            try await CameraVideoSource.shared().startCapturing(with: frontCamera, options: nil)
        } catch {
            throw NSError(domain: "SkywayError", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to start the camera: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Room Handling
    func joinRoom(room: Room, userName: String, roomType: RoomType) async throws -> LocalRoomMember {
        DispatchQueue.main.sync { roomJoiningStatus = .joining }
        
        let memberOpt: Room.MemberInitOptions = .init()
        memberOpt.name = userName
        
        do {
            let localMember = try await room.join(with: memberOpt)
            self.room = room
            room.delegate = self
            self.localMember = localMember
            
            print("[Join Room][Member name]: \(localMember.name ?? "No Name")")
            DispatchQueue.main.sync { roomJoiningStatus = .joined }
            return localMember
        } catch {
            print("[Error] Room joining failed: \(error.localizedDescription)")
            DispatchQueue.main.sync { roomJoiningStatus = .failedToJoin }
            throw error
        }
    }
    
    func findRoom(roomName: String, roomType: RoomType) async throws -> Room {
        DispatchQueue.main.sync { roomFindStatus = .searching }
        
        let query: SkyWayRoom.Room.Query = .init()
        query.name = roomName
        
        do {
            let room: Room
            if roomType == .P2P {
                room = try await P2PRoom.find(by: query)
            } else {
                room = try await SFURoom.find(by: query)
            }
            DispatchQueue.main.sync { remotePublications = room.publications }
            self.room = room
            room.delegate = self
            DispatchQueue.main.sync { roomFindStatus = .found }
            return room
        } catch {
            print("[Error] Room finding failed: \(error.localizedDescription)")
            DispatchQueue.main.sync { roomFindStatus = .notFound }
            throw error
        }
    }
    
    func createRoom(roomName: String, roomType: RoomType) async throws -> Room {
        DispatchQueue.main.sync { roomCreationStatus = .creating }
        
        let opt: Room.InitOptions = .init()
        opt.name = roomName
        
        do {
            let room: Room
            if roomType == .P2P {
                room = try await P2PRoom.create(with: opt)
            } else {
                room = try await SFURoom.create(with: opt)
            }
            DispatchQueue.main.sync { remotePublications = room.publications }
            self.room = room
            room.delegate = self
            DispatchQueue.main.sync { roomCreationStatus = .created }
            return room
        } catch {
            DispatchQueue.main.sync { roomCreationStatus = .createFailed }
            throw error
        }
    }
    
    func leave() async throws {
        room?.delegate = nil
        dataStream = nil
        speechRecognizer.stopTranscribing()
        
        do {
            try await localMember?.leave()
        } catch {
            print("Error leaving the room: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.sync {
            remotePublications = []
            localSubscriptions = []
            receivedMessage = []
        }
        
        do {
            try await room?.dispose()
        } catch {
            print("Error disposing the room: \(error.localizedDescription)")
        }
        
        localMember = nil
        room = nil
    }
    
    func disposeContext() async throws {
        try await Context.dispose()
    }
    
    // MARK: - Publish / Subscribe
    func publishStreams(includeDataStream: Bool = true) async throws {
        let audioStream = MicrophoneAudioSource().createStream()
        let videoStream = CameraVideoSource.shared().createStream()
        
        // Audio
        let audioOptions: RoomPublicationOptions = .init()
        if let audioPub = try await localMember?.publish(audioStream, options: audioOptions) {
            self.audioPublication = audioPub
            do {
                try speechRecognizer.startTranscribing()
            } catch {
                print("Speech recognizer failed: \(error.localizedDescription)")
            }
        }
        
        // Video
        let videoOptions: RoomPublicationOptions = .init()
        if room is SFURoom {
            let highEnc: Encoding = .init()
            highEnc.id = highEncodeId
            highEnc.scaleResolutionDownBy = 1.0
            
            videoOptions.encodings = [highEnc]
        } else {
            let enc: Encoding = .init()
            enc.scaleResolutionDownBy = 1.0
            videoOptions.encodings = [enc]
        }
        
        if let videoPub = try await localMember?.publish(videoStream, options: videoOptions) {
            self.videoPublication = videoPub
        }
        
        // Data
        if room is P2PRoom && includeDataStream {
            dataStream = DataSource().createStream()
            let _ = try await localMember?.publish(dataStream!, options: nil)
        }
    }
    
    func subscribe(publication: RoomPublication) async throws -> RoomSubscription? {
        guard publication.publisher != localMember,
              let localMember = localMember else { return nil }
        
        let sub = try await localMember.subscribe(publicationId: publication.id, options: .init())
        
        if let dataStream = sub.stream as? RemoteDataStream {
            dataStream.delegate = self
        }
        
        DispatchQueue.main.sync {
            localSubscriptions.append(sub)
        }
        return sub
    }
    
    func unsubscribe(subscriptionId: String) async throws {
        try await localMember?.unsubscribe(subscriptionId: subscriptionId)
        DispatchQueue.main.sync {
            localSubscriptions.removeAll { $0.id == subscriptionId }
        }
    }
    
    // MARK: - Messaging
    func sendMessage(_ message: String) {
        guard let dataStream = dataStream else { return }
        print("[Message to send]: \(message)")
        dataStream.write(message)
        sentMessages.append(message)
        updateAllMessages()
    }
    
    func updateAllMessages() {
        allMessages.removeAll()
        
        let decodedReceived = receivedMessage.compactMap { json in
            if var msg = decodeJSONToMessage(jsonString: json) {
                msg.type = "received"
                return msg
            }
            return nil
        }
        
        let decodedSent = sentMessages.compactMap { json in
            if var msg = decodeJSONToMessage(jsonString: json) {
                msg.type = "sent"
                return msg
            }
            return nil
        }
        
        allMessages = (decodedReceived + decodedSent).sorted { $0.timeStamp < $1.timeStamp }
    }
    
    // MARK: - Encodings
    func changePreferredEncoding(subscriptionId: String, encodingId: String) {
        guard let sub = room?.subscriptions.first(where: { $0.id == subscriptionId }) else {
            print("[App] Subscription is missing")
            return
        }
        sub.changePreferredEncoding(encodingId: encodingId)
    }
    
    func toggleVideoEncoding(roomType: RoomType) {
        guard let videoPub = localMember?.publications.first(where: { $0.contentType == .video }) else { return }
        
        let newEncoding: Encoding = .init()
        if currentEncoding == highEncodeId {
            newEncoding.scaleResolutionDownBy = 8.0
            currentEncoding = lowEncodeId
        } else {
            newEncoding.scaleResolutionDownBy = 1.0
            currentEncoding = highEncodeId
        }
        videoPub.update([newEncoding])
        print("[App] Encodings updated")
    }
    
    // MARK: - RoomDelegate
    func room(_ room: Room, didPublishStreamOf publication: RoomPublication) {
        guard let localMember = localMember else { return }
        
        if publication.publisher != localMember, isAutoSubscribing {
            Task {
                guard let sub = try? await localMember.subscribe(publicationId: publication.id, options: nil) else { return }
                if let dataStream = sub.stream as? RemoteDataStream {
                    dataStream.delegate = self
                }
                DispatchQueue.main.sync {
                    localSubscriptions.append(sub)
                }
            }
        }
    }
    
    func room(_ room: Room, didUnsubscribePublicationOf subscription: RoomSubscription) {
        DispatchQueue.main.sync {
            localSubscriptions.removeAll { $0 == subscription }
        }
    }
    
    func roomPublicationListDidChange(_ room: Room) {
        DispatchQueue.main.sync {
            remotePublications = room.publications.filter { $0.publisher != localMember }
        }
    }
    
    // MARK: - RemoteDataStreamDelegate
    func dataStream(_ dataStream: RemoteDataStream, didReceive string: String) {
        DispatchQueue.main.sync {
            receivedMessage.append(string)
            print("[Message Received]: \(string)\n\n")
            updateAllMessages()
        }
    }
    
    // MARK: - Messages
    func encodeMessageToJSON(message: Message) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(message)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding message to JSON: \(error)")
            return nil
        }
    }
    
    func decodeJSONToMessage(jsonString: String) -> Message? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            return try decoder.decode(Message.self, from: data)
        } catch {
            print("Error decoding JSON to message: \(error)")
            return nil
        }
    }
    
    func onSendMessage(message: String) {
        if !message.isEmpty {
            let messageObject = Message(
                message: message,
                type: "sent",
                timeStamp: Date(),
                sender: localMember?.name ?? "Anonymous"
            )
            
            if let jsonMessage = encodeMessageToJSON(message: messageObject) {
                sendMessage(jsonMessage)
            }
        }
    }
}

// MARK: - Media Controls
extension SkyWayViewModel {
    func toggleVideo() async {
        guard let videoPub = videoPublication else { return }
        
        do {
            if isVideoEnabled {
                try await videoPub.disable()
                DispatchQueue.main.async(execute: {
                    self.isVideoEnabled = false
                })
    
                print("[App] Video disabled")
            } else {
                
                try await videoPub.enable()
                DispatchQueue.main.async(execute: {
                    self.isVideoEnabled = true
                })
                print("[App] Video enabled")
            }
        } catch {
            print("[Error] Failed to toggle video: \(error.localizedDescription)")
        }
    }
    
    func toggleAudio() async {
        guard let audioPub = audioPublication else { return }
        
        do {
            if isAudioEnabled {
                try await audioPub.disable()
                DispatchQueue.main.async(execute: {
                    self.isAudioEnabled = false
                })
                print("[App] Audio muted")
                
                // Pause recognition again when unmuted
                speechRecognizer.pauseTranscribing = true
            } else {
                try await audioPub.enable()
                DispatchQueue.main.async(execute: {
                    self.isAudioEnabled = true
                })
                print("[App] Audio unmuted")
                
                // Unpause recognition again when unmuted
                speechRecognizer.pauseTranscribing = false
            }
        } catch {
            print("[Error] Failed to toggle audio: \(error.localizedDescription)")
        }
    }
}


// MARK: - ContentType Extension
extension ContentType {
    func toString() -> String {
        switch self {
        case .audio: return "Audio"
        case .video: return "Video"
        case .data: return "Data"
        @unknown default: fatalError()
        }
    }
}
