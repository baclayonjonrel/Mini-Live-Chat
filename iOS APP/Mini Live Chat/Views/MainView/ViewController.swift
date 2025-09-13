//
//  ViewController.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 1/21/25.
//

import UIKit
import SwiftUI
import AudioToolbox

class ViewController: UIViewController {
    @ObservedObject var skyway: SkyWayViewModel = .init()
    @ObservedObject var callvm: CallViewModel = .init()
    @ObservedObject var chatvm: ChatViewModel = .init()
    
    @IBOutlet weak var tableView: UITableView!
    private let searchController = UISearchController(searchResultsController: nil)
    private var threads: [ThreadResponse] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUserStatus()
        
        title = "Messages"
        navigationItem.largeTitleDisplayMode = .always
        
        // Left "Edit" button
        let editButton = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )

        // Profile button (can be text or an image)
        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )

        let composeButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(composeTapped)
        )
        
        // Assign both buttons
        navigationItem.leftBarButtonItems = [editButton]
        navigationItem.rightBarButtonItems = [profileButton, composeButton]
        
        // MARK: - Search
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
        // TableView setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ThreadCell.self, forCellReuseIdentifier: "ThreadCell")
        tableView.rowHeight = 70
        
        // Add observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallUpdate(_:)),
            name: .callUpdateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMessageUpdate(_:)),
            name: .messageUpdateNotification,
            object: nil
        )
    }
    
    // MARK: - Notification handler
    
    @objc private func handleMessageUpdate(_ notification: Notification) {
        guard let payloadData = notification.userInfo?["payload"] as? Data,
              let payload = try? JSONDecoder().decode(CommandPayload.self, from: payloadData) else {
            print("Failed to decode call payload")
            return
        }

        let sender = payload.sender
        if let currentPeerActiveCallID = chatvm.currentPeerActive, currentPeerActiveCallID._id == sender._id {
            if let action = payload.action {
                if action == "typing" {
                    chatvm.isTyping = true
                } else if action == "notTyping" {
                    chatvm.isTyping = false
                } else if action == "seen" {
                    for i in 0..<chatvm.messages.count {
                        chatvm.messages[i].status = .seen
                    }
                }
            } else {
                NotificationCenter.default.post(
                    name: .refreshMessagesNotification,
                    object: nil
                )
            }
        } else {
            if let action = payload.action {
                print("action given, do nothing \(action)")
            } else {
                AppUtility.shared.showInAppNotification(senderName: sender.displayName, messageText: "\(sender.displayName) sent you a message!")
                self.fetchThreads()
            }
            
        }
    }
    
    @objc private func handleCallUpdate(_ notification: Notification) {
        guard let payloadData = notification.userInfo?["payload"] as? Data,
              let payload = try? JSONDecoder().decode(CommandPayload.self, from: payloadData) else {
            print("Failed to decode call payload")
            return
        }

        let action = payload.action ?? ""
        let text = payload.text ?? ""
        let sender = payload.sender

        print("Action: \(action), Text: \(text), Sender: \(sender.displayName)")

        switch action {
        case CallAction.initiateOutgoingCall.rawValue:
            callvm.callStatus = .initiated
            print("Handle outgoing call start")
            if !text.isEmpty {
                AppUtility.shared.showIncomingCall(callvm: callvm, callPeer: sender, roomName: text)
            }
        case CallAction.cancelOutgoingCall.rawValue:
            callvm.callStatus = .disconnected
            print("Handle outgoing call cancel")
        case CallAction.disconnectOngoingCall.rawValue:
            callvm.callStatus = .disconnected
            print("Handle call disconnect")
        case CallAction.acceptIncomingCall.rawValue:
            callvm.callStatus = .connected
            print("Handle call accept")
        case CallAction.rejectIncomingCall.rawValue:
            callvm.callStatus = .disconnected
            print("Handle call reject")
        default:
            print("Unhandled call action: \(action)")
        }
    }

    deinit {
        // Remove observer to avoid memory leaks
        NotificationCenter.default.removeObserver(self)
    }
        
    func checkUserStatus() {
        if let _ = UserDefaults.standard.string(forKey: "loginToken") {
            // token exist fetch user
            if AppUtility.shared.currentUser == nil {
                AppUtility.shared.fetchCurrentUser { result in
                    switch result {
                        case .success(let user):
                        AppUtility.shared.currentUser = user.user
                        print("user debug: \(user)")
                        self.fetchThreads()
                    case .failure(let error as NSError):
                        print("user debug: \(error.code)")
                        if error.code == 401 {
                            UserDefaults.standard.removeObject(forKey: "loginToken")
                            AppUtility.shared.currentUser = nil
                            self.threads.removeAll()
                            self.showAuthView()
                        }
                    }
                }
            } else {
                self.fetchThreads()
            }
        } else {
            DispatchQueue.main.async {
                self.showAuthView()
            }
        }
    }
    
    func fetchThreads() {
        AppUtility.shared.fetchThreads { result in
            switch result {
            case .success(let threads):
                self.threads = threads
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                print("message debug: \(threads)")
            case .failure(let error):
                print("message debug: \(error)")
            }
        }
    }
    
    @objc private func profileTapped() {
        print("Profile tapped")
        if let user = AppUtility.shared.currentUser {
            showProfileView(user: user)
        }
    }
    
    private func showProfileView(user: User) {
        let view = ProfileView(user: user) {
            self.checkUserStatus()
        }
        let hostingVC = UIHostingController(rootView: view)
        hostingVC.modalPresentationStyle = .formSheet
        DispatchQueue.main.async {
            self.present(hostingVC, animated: true , completion: nil)
        }
    }
    
    @objc private func editTapped() {
        print("Edit tapped")
    }

    @objc private func composeTapped() {
        showComposeView()
    }
    
    private func showComposeView() {
        let composeMessageView = ComposeMessageView() {
            self.checkUserStatus()
        }
        let hostingVC = UIHostingController(rootView: composeMessageView)
        hostingVC.modalPresentationStyle = .formSheet
        DispatchQueue.main.async {
            self.present(hostingVC, animated: true , completion: nil)
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
//    
//    private func showCreateRoomView() {
//        let createRoomView = CreateRoomView(call)
//        let hostingVC = UIHostingController(rootView: createRoomView)
//        hostingVC.modalPresentationStyle = .fullScreen
//        DispatchQueue.main.async {
//            self.present(hostingVC, animated: true , completion: nil)
//        }
//    }
//    
//    private func showJoinRoomView() {
//        let joinRoomView = JoinRoomView()
//        let hostingVC = UIHostingController(rootView: joinRoomView)
//        hostingVC.modalPresentationStyle = .fullScreen
//        DispatchQueue.main.async {
//            self.present(hostingVC, animated: true , completion: nil)
//        }
//    }
    
    private func showAuthView() {
        let authView = Authentication() {
            self.checkUserStatus()
        }
        let hostingVC = UIHostingController(rootView: authView)
        hostingVC.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(hostingVC, animated: true , completion: nil)
        }
    }
    
    private func showMessagesView(threadPeer: ThreadResponse) {
        var view = ChatMessagesView(vm: chatvm, callvm: callvm) {
            self.fetchThreads()
        }
        view.threadPeer = threadPeer
        let hostingVC = UIHostingController(rootView: view)
        hostingVC.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {
            self.present(hostingVC, animated: true , completion: nil)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadCell", for: indexPath) as? ThreadCell else {
            return UITableViewCell()
        }
        let thread = threads[indexPath.row]
        cell.configure(with: thread)
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected thread with \(threads[indexPath.row].id)")
        tableView.deselectRow(at: indexPath, animated: true)
        showMessagesView(threadPeer: threads[indexPath.row])
    }
}

