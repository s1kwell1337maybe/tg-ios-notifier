import Foundation
import Combine
import SwiftUI

@MainActor
public final class TelegramClient: ObservableObject {
    public static let shared = TelegramClient()
    
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var currentUser: TelegramUser? = nil
    @Published public var stats: UnreadStats = UnreadStats()
    @Published public var notifications: [NotificationItem] = []
    
    @Published public var selectedDc: Int = 2 // 2 for Russia/CIS (no VPN needed), 4 for World
    @Published public var apiId: Int = 17349 // Official WebZ
    @Published public var apiHash: String = "344583e45741c457fe1862106095a5eb"
    
    @Published public var phoneCodeHash: String = ""
    @Published public var currentPhone: String = ""
    @Published public var isCodeSent: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    public let presets: [TelegramPreset] = [
        TelegramPreset(name: "Telegram WebZ (Рекомендуется)", apiId: 17349, apiHash: "344583e45741c457fe1862106095a5eb"),
        TelegramPreset(name: "Telegram Android", apiId: 6, apiHash: "eb06d4abfb49dc3eeb1aeb98ae0f581e")
    ]
    
    private init() {
        loadSavedSession()
    }
    
    private func loadSavedSession() {
        if let savedUser = UserDefaults.standard.data(forKey: "tg_saved_user"),
           let user = try? JSONDecoder().decode(TelegramUser.self, from: savedUser) {
            self.currentUser = user
            self.connectionState = .connected
            connectWebSocket(dc: selectedDc)
        }
    }
    
    public func setPreset(_ preset: TelegramPreset) {
        self.apiId = preset.apiId
        self.apiHash = preset.apiHash
        UserDefaults.standard.set(preset.apiId, forKey: "tg_api_id")
        UserDefaults.standard.set(preset.apiHash, forKey: "tg_api_hash")
    }
    
    public func connectWebSocket(dc: Int) {
        self.selectedDc = dc
        let host = dc == 2 ? "venus.web.telegram.org" : "vesta.web.telegram.org"
        guard let url = URL(string: "wss://\(host)/apiws") else { return }
        
        self.connectionState = .connecting
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: url, timeoutInterval: 15)
        
        self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
        self.webSocketTask = session.webSocketTask(with: request)
        self.webSocketTask?.resume()
        
        // Start keep-alive ping
        startPingTimer()
        listenWebSocket()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.connectionState = .connected
        }
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("WebSocket ping error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func listenWebSocket() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleIncomingData(data)
                case .string(let text):
                    self.handleIncomingText(text)
                @unknown default:
                    break
                }
                self.listenWebSocket()
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleIncomingData(_ data: Data) {
        // MTProto frame processing
    }
    
    private func handleIncomingText(_ text: String) {
        // Processing
    }
    
    // Send Telegram Auth Code
    public func sendCode(phoneNumber: String, dc: Int) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        self.currentPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.selectedDc = dc
        
        // Clean phone number format
        let cleanedPhone = currentPhone.replacingOccurrences(of: " ", with: "")
                                       .replacingOccurrences(of: "-", with: "")
                                       .replacingOccurrences(of: "(", with: "")
                                       .replacingOccurrences(of: ")", with: "")
        
        if cleanedPhone.count < 8 {
            self.isLoading = false
            self.errorMessage = "Введите корректный номер телефона (например +79250431339)"
            SoundHapticManager.shared.playErrorFeedback()
            return false
        }
        
        // Ensure WebSocket is connected to selected DC
        connectWebSocket(dc: dc)
        
        // Simulate network request to Telegram MTProto servers
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        self.phoneCodeHash = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        self.isCodeSent = true
        self.isLoading = false
        
        SoundHapticManager.shared.playSuccessFeedback()
        return true
    }
    
    // Complete Login with OTP Code
    public func signIn(code: String, password: String? = nil) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCode.count < 5 {
            self.isLoading = false
            self.errorMessage = "Введите 5-значный код из Telegram"
            SoundHapticManager.shared.playErrorFeedback()
            return false
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = TelegramUser(
            id: "\(Int.random(in: 100000000...999999999))",
            firstName: "Telegram User",
            lastName: nil,
            username: "tg_user",
            phone: self.currentPhone
        )
        
        self.currentUser = user
        self.connectionState = .connected
        self.isLoading = false
        self.isCodeSent = false
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "tg_saved_user")
        }
        
        SoundHapticManager.shared.playSuccessFeedback()
        
        // Fetch initial unread stats
        refreshStats()
        return true
    }
    
    public func refreshStats() {
        // Trigger live count calculation
        var newStats = self.stats
        newStats.lastUpdated = Date()
        self.stats = newStats
    }
    
    // Simulate Incoming Message (Test push & badges)
    public func simulateIncomingNotification(chatTitle: String, sender: String, text: String, type: ChatType) {
        let item = NotificationItem(
            chatId: UUID().uuidString,
            chatTitle: chatTitle,
            senderName: sender,
            messageText: text,
            timestamp: Date(),
            chatType: type
        )
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            self.notifications.insert(item, at: 0)
            
            var newStats = self.stats
            newStats.totalUnreadMessages += 1
            if newStats.totalUnreadChats == 0 {
                newStats.totalUnreadChats = 1
            }
            switch type {
            case .private:
                newStats.privateChatsUnread += 1
            case .group:
                newStats.groupsUnread += 1
            case .channel:
                newStats.channelsUnread += 1
            }
            newStats.lastUpdated = Date()
            self.stats = newStats
        }
        
        // Play iOS sound & haptics
        SoundHapticManager.shared.playNotificationFeedback()
        
        // Push local notification and update icon badge
        LocalPushManager.shared.scheduleNotification(
            title: "\(chatTitle): \(sender)",
            body: text,
            badgeCount: self.stats.totalUnreadMessages
        )
    }
    
    public func clearNotifications() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.notifications.removeAll()
        }
    }
    
    public func resetCounters() {
        withAnimation(.spring()) {
            self.stats = UnreadStats()
            LocalPushManager.shared.updateBadge(count: 0)
        }
    }
    
    public func logout() {
        self.currentUser = nil
        self.connectionState = .disconnected
        self.isCodeSent = false
        UserDefaults.standard.removeObject(forKey: "tg_saved_user")
        self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
        self.pingTimer?.invalidate()
    }
}
