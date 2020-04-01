//
//  ChatViewModel.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/20/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Combine
import SwiftUI

final class ChatViewModel: NSObject, ObservableObject {
    enum AppState: String {
        case inactive = "Inactive"
        case searchingForChat = "Searching for Chat"
        case connectedToHost = "Connected to Host"
        case hostingAwaitingPeers = "Waiting for Peers"
        case hostingWithPeers = "Hosting Chat"
        
        var notConnected: Bool { [AppState.connectedToHost, AppState.hostingWithPeers].contains(self) == false }
    }
    
    static let serviceType = "local-crosstalk"
    static var safeAreaInsetBottom: CGFloat { UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0 }
    
    @Published private(set) var appState = AppState.inactive
    @Published var newMessageText = ""
    
    @Published private(set) var messages = [Message(username: User.local.name,
                                       value: "Hello, world!",
                                       timestamp: "",
                                       languageCode: "en",
                                       translationLanguageCode: "",
                                       translatedValue: "")]
    
    @Published var isTranslating = false
    @Published private(set) var keyboardOffset: CGFloat = 0
    @Published private(set) var keyboardAnimationDuration: Double = 0
    
    lazy var session: MCSession = {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    var timestamp: String { formatter.string(from: Date()) }
    var newMessageTextIsEmpty: Bool { newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    let translationLanguageCode = "nl"
    var actionSheetTitle = "Actions"
    
    private lazy var advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
    private lazy var browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
    private lazy var peerID = MCPeerID(displayName: UIDevice.current.name)
    private var hostID: MCPeerID?
    private let formatter = DateFormatter(dateStyle: .short, timeStyle: .short)
    private lazy var decoder = JSONDecoder()
    private lazy var translationService = TranslationService()
    private var subscriptions = Set<AnyCancellable>()
        
    override init() {
        super.init()
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .handleEvents(receiveOutput: { [weak self] _ in self?.keyboardOffset = 0 })
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification))
            .map(\.userInfo)
            .compactMap { ($0?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue }
            .assign(to: \.keyboardAnimationDuration, on: self)
            .store(in: &subscriptions)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .map(\.userInfo)
            .compactMap { ($0?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.size.height }
            .map { $0 * -1 + Self.safeAreaInsetBottom }
            .assign(to: \.keyboardOffset, on: self)
            .store(in: &subscriptions)
    }
    
    func clear() {
        newMessageText = ""
    }
    
    func send() {
        guard newMessageTextIsEmpty == false else { return }
        
        let message = Message(username: User.local.name,
                              value: newMessageText,
                              timestamp: timestamp,
                              languageCode: "",
                              translationLanguageCode: "",
                              translatedValue: "")
        
        insert(message: message)
        newMessageText = ""
        
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func startAdvertising() {
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        appState = .hostingAwaitingPeers
        hostID = peerID
    }
    
    func startBrowsing() {
        browser.delegate = self
        browser.startBrowsingForPeers()
        appState = .searchingForChat
    }
    
    func disconnect() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        hostID = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.appState = .inactive
        }
    }
    
    func fetchTranslation(for message: Message, to translationLanguageCode: String) -> AnyPublisher<Message, Never> {
      guard message.languageCode != translationLanguageCode else {
        return Just(message).eraseToAnyPublisher()
      }
      
      return translationService.publisher(for: message, to: translationLanguageCode)
        .retry(1)
        .decode(type: TranslationResponse.self, decoder: decoder)
        .compactMap { $0.translations.first }
        .map { translatedValue in
            Message(username: message.username,
                    value: message.value,
                    timestamp: message.timestamp,
                    languageCode: message.languageCode,
                    translationLanguageCode: translationLanguageCode,
                    translatedValue: translatedValue == message.value ? "" : translatedValue)
        }
        .replaceError(with: message)
        .eraseToAnyPublisher()
    }
    
    private func insert(message: Message) {
        DispatchQueue.main.async { [weak self] in
            self?.messages.insert(message, at: 0)
        }
    }
}

extension ChatViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.session = session
        
        guard state != .connecting,
            hostID == self.peerID, // I am the host...
            peerID != self.peerID // ...and didChange is not from me
            else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.appState = session.connectedPeers.isEmpty ? .hostingAwaitingPeers : .hostingWithPeers
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try decoder.decode(Message.self, from: data)
            
            if isTranslating {
                fetchTranslation(for: message, to: translationLanguageCode)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] in
                        self?.insert(message: $0)
                    })
                    .store(in: &subscriptions)
            } else {
                insert(message: try decoder.decode(Message.self, from: data))
            }
        } catch {
            print(error)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

extension ChatViewModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        appState = .hostingWithPeers
    }
}

extension ChatViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        appState = .connectedToHost
        hostID = peerID
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if hostID == peerID {
            disconnect()
            self.hostID = nil
        }
    }
}
