import Foundation
import WebKit
import SwiftUI
import Combine

// MARK: - Real MTProto 2.0 Native Bridge Client
// Runs fully bundled Telegram MTProto Web engine locally inside native iOS WebKit WKWebView
// Supports Direct MTProto & Anti-Censorship Edge Relay without VPN.

@MainActor
public final class TelegramClient: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {
    public static let shared = TelegramClient()
    
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var currentUser: TelegramUser? = nil
    @Published public var stats: UnreadStats = UnreadStats()
    @Published public var notifications: [NotificationItem] = []
    
    @Published public var selectedDc: Int = 4
    @Published public var apiId: Int = 17349
    @Published public var apiHash: String = "344583e45741c457fe1862106095a5eb"
    
    @Published public var currentPhone: String = ""
    @Published public var isCodeSent: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var requires2FA: Bool = false
    
    private var webView: WKWebView?
    private var isEngineReady: Bool = false
    private var pendingSendCodeContinuation: CheckedContinuation<Bool, Never>?
    private var pendingSignInContinuation: CheckedContinuation<Bool, Never>?
    
    public let presets: [TelegramPreset] = [
        TelegramPreset(name: "Telegram WebZ (Рекомендуется)", apiId: 17349, apiHash: "344583e45741c457fe1862106095a5eb"),
        TelegramPreset(name: "Telegram Android", apiId: 6, apiHash: "eb06d4abfb49dc3eeb1aeb98ae0f581e")
    ]
    
    override private init() {
        super.init()
        loadSavedSession()
        setupEngine()
    }
    
    // MARK: - Persistent Session Restoration
    private func loadSavedSession() {
        let savedSession = UserDefaults.standard.string(forKey: "tg_saved_session") ?? ""
        let savedUserId = UserDefaults.standard.string(forKey: "tg_saved_user_id") ?? ""
        let savedFirstName = UserDefaults.standard.string(forKey: "tg_saved_user_first_name") ?? ""
        let savedLastName = UserDefaults.standard.string(forKey: "tg_saved_user_last_name")
        let savedUsername = UserDefaults.standard.string(forKey: "tg_saved_user_username")
        let savedPhone = UserDefaults.standard.string(forKey: "tg_saved_user_phone")
        let savedDc = UserDefaults.standard.integer(forKey: "tg_saved_dc")
        
        if savedDc > 0 {
            self.selectedDc = savedDc
        }
        
        if !savedSession.isEmpty && !savedUserId.isEmpty {
            self.currentUser = TelegramUser(
                id: savedUserId,
                firstName: savedFirstName.isEmpty ? "Telegram User" : savedFirstName,
                lastName: savedLastName,
                username: savedUsername,
                phone: savedPhone
            )
            self.connectionState = .connecting
        } else {
            self.connectionState = .disconnected
        }
    }
    
    private func setupEngine() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "tgNativeBridge")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        self.webView = wv
        
        if let htmlURL = Bundle.main.url(forResource: "engine", withExtension: "html") {
            wv.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        } else if let jsURL = Bundle.main.url(forResource: "telegram_engine", withExtension: "js"),
                  let jsContent = try? String(contentsOf: jsURL, encoding: .utf8) {
            let inlineHTML = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"></head>
            <body><script>\(jsContent)</script></body>
            </html>
            """
            wv.loadHTMLString(inlineHTML, baseURL: URL(string: "https://web.telegram.org"))
        } else {
            let fallbackHTML = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"></head>
            <body></body>
            </html>
            """
            wv.loadHTMLString(fallbackHTML, baseURL: URL(string: "https://web.telegram.org"))
        }
    }
    
    // MARK: - Native Message Handler from Real MTProto Engine
    nonisolated public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let type = dict["type"] as? String else { return }
        
        let payload = dict["payload"] as? [String: Any] ?? [:]
        
        Task { @MainActor in
            self.handleBridgeMessage(type: type, payload: payload)
        }
    }
    
    private func handleBridgeMessage(type: String, payload: [String: Any]) {
        switch type {
        case "ENGINE_READY":
            self.isEngineReady = true
            let savedSession = UserDefaults.standard.string(forKey: "tg_saved_session") ?? ""
            if !savedSession.isEmpty {
                let escapedSession = savedSession
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                executeJS("window.initTelegram(\(apiId), '\(apiHash)', '\(escapedSession)', \(selectedDc));")
            } else {
                self.connectionState = .disconnected
            }
            
        case "CONNECTED":
            self.connectionState = .connected
            if let dc = payload["dc"] as? Int {
                self.selectedDc = dc
                UserDefaults.standard.set(dc, forKey: "tg_saved_dc")
            }
            
        case "CODE_SENT":
            self.isLoading = false
            self.isCodeSent = true
            self.errorMessage = nil
            if let dc = payload["dc"] as? Int {
                self.selectedDc = dc
                UserDefaults.standard.set(dc, forKey: "tg_saved_dc")
            }
            SoundHapticManager.shared.playSuccessFeedback()
            self.pendingSendCodeContinuation?.resume(returning: true)
            self.pendingSendCodeContinuation = nil
            
        case "SEND_CODE_ERROR":
            self.isLoading = false
            let msg = payload["message"] as? String ?? "Ошибка отправки кода"
            if msg.contains("PHONE_NUMBER_INVALID") {
                self.errorMessage = "Неверный формат номера телефона (пример: +7 925 043 1339)"
            } else if msg.contains("FLOOD_WAIT") {
                self.errorMessage = "Слишком много попыток. Пожалуйста, подождите несколько минут"
            } else {
                self.errorMessage = "Ошибка Telegram: \(msg)"
            }
            SoundHapticManager.shared.playErrorFeedback()
            self.pendingSendCodeContinuation?.resume(returning: false)
            self.pendingSendCodeContinuation = nil
            
        case "AUTH_SUCCESS":
            self.isLoading = false
            self.isCodeSent = false
            self.requires2FA = false
            self.errorMessage = nil
            
            let user = TelegramUser(
                id: payload["id"] as? String ?? "unknown",
                firstName: payload["firstName"] as? String ?? "User",
                lastName: payload["lastName"] as? String,
                username: payload["username"] as? String,
                phone: payload["phone"] as? String ?? self.currentPhone
            )
            self.currentUser = user
            self.connectionState = .connected
            
            if let sessionStr = payload["session"] as? String {
                UserDefaults.standard.set(sessionStr, forKey: "tg_saved_session")
                UserDefaults.standard.set(user.id, forKey: "tg_saved_user_id")
                UserDefaults.standard.set(user.firstName, forKey: "tg_saved_user_first_name")
                UserDefaults.standard.set(user.lastName ?? "", forKey: "tg_saved_user_last_name")
                UserDefaults.standard.set(user.username ?? "", forKey: "tg_saved_user_username")
                UserDefaults.standard.set(user.phone ?? "", forKey: "tg_saved_user_phone")
                UserDefaults.standard.set(self.selectedDc, forKey: "tg_saved_dc")
            }
            
            LiveActivityManager.shared.startOrUpdateLiveActivity(
                unreadCount: self.stats.totalUnreadMessages,
                lastSender: user.displayName,
                lastMessage: "Подключено к Telegram MTProto"
            )
            
            SoundHapticManager.shared.playSuccessFeedback()
            self.pendingSignInContinuation?.resume(returning: true)
            self.pendingSignInContinuation = nil
            
        case "2FA_REQUIRED":
            self.isLoading = false
            self.requires2FA = true
            self.errorMessage = "Требуется пароль двухфакторной аутентификации (2FA)"
            SoundHapticManager.shared.playErrorFeedback()
            self.pendingSignInContinuation?.resume(returning: false)
            self.pendingSignInContinuation = nil
            
        case "SIGN_IN_ERROR":
            self.isLoading = false
            let msg = payload["message"] as? String ?? "Ошибка проверки кода"
            if msg.contains("PHONE_CODE_INVALID") {
                self.errorMessage = "Неверный код подтверждения. Проверьте сообщение в Telegram"
            } else if msg.contains("PHONE_CODE_EXPIRED") {
                self.errorMessage = "Срок действия кода истек. Запросите код заново"
            } else {
                self.errorMessage = "Ошибка авторизации: \(msg)"
            }
            SoundHapticManager.shared.playErrorFeedback()
            self.pendingSignInContinuation?.resume(returning: false)
            self.pendingSignInContinuation = nil
            
        case "ERROR":
            self.isLoading = false
            self.connectionState = .disconnected
            let msg = payload["message"] as? String ?? ""
            if msg.contains("AUTH_KEY_UNREGISTERED") || msg.contains("SESSION_REVOKED") || msg.contains("timeout") || msg.contains("SESSION_EXPIRED") {
                self.currentUser = nil
                UserDefaults.standard.removeObject(forKey: "tg_saved_session")
                UserDefaults.standard.removeObject(forKey: "tg_saved_user_id")
            }
            self.pendingSendCodeContinuation?.resume(returning: false)
            self.pendingSendCodeContinuation = nil
            self.pendingSignInContinuation?.resume(returning: false)
            self.pendingSignInContinuation = nil
            
        case "SESSION_EXPIRED", "DISCONNECTED":
            self.isLoading = false
            self.connectionState = .disconnected
            self.currentUser = nil
            UserDefaults.standard.removeObject(forKey: "tg_saved_session")
            UserDefaults.standard.removeObject(forKey: "tg_saved_user_id")
            
        case "LOGOUT_SUCCESS":
            self.isLoading = false
            self.connectionState = .disconnected
            self.currentUser = nil
            self.isCodeSent = false
            self.requires2FA = false
            
        case "NEW_MESSAGE":
            let rawType = payload["chatType"] as? String ?? "private"
            let chatType: ChatType = rawType == "group" ? .group : (rawType == "channel" ? .channel : .private)
            
            let item = NotificationItem(
                id: payload["id"] as? String ?? UUID().uuidString,
                chatId: payload["chatId"] as? String ?? "",
                chatTitle: payload["chatTitle"] as? String ?? "Telegram",
                senderName: payload["senderName"] as? String ?? "Пользователь",
                messageText: payload["messageText"] as? String ?? "",
                timestamp: Date(),
                chatType: chatType
            )
            
            withAnimation(.spring()) {
                self.notifications.insert(item, at: 0)
            }
            
            SoundHapticManager.shared.playNotificationFeedback()
            LocalPushManager.shared.scheduleNotification(
                title: "\(item.chatTitle): \(item.senderName)",
                body: item.messageText,
                badgeCount: self.stats.totalUnreadMessages + 1
            )
            
            LiveActivityManager.shared.startOrUpdateLiveActivity(
                unreadCount: self.stats.totalUnreadMessages + 1,
                lastSender: item.senderName,
                lastMessage: item.messageText,
                chatTitle: item.chatTitle
            )
            
        case "UNREAD_STATS":
            var newStats = UnreadStats()
            newStats.totalUnreadMessages = payload["totalUnreadMessages"] as? Int ?? 0
            newStats.totalUnreadChats = payload["totalUnreadChats"] as? Int ?? 0
            newStats.privateChatsUnread = payload["privateChatsUnread"] as? Int ?? 0
            newStats.groupsUnread = payload["groupsUnread"] as? Int ?? 0
            newStats.channelsUnread = payload["channelsUnread"] as? Int ?? 0
            newStats.mentionsCount = payload["mentionsCount"] as? Int ?? 0
            newStats.lastUpdated = Date()
            
            withAnimation(.spring()) {
                self.stats = newStats
            }
            LocalPushManager.shared.updateBadge(count: newStats.totalUnreadMessages)
            
            LiveActivityManager.shared.startOrUpdateLiveActivity(
                unreadCount: newStats.totalUnreadMessages,
                lastSender: self.currentUser?.displayName ?? "Telegram",
                lastMessage: "Непрочитанных: \(newStats.totalUnreadMessages)"
            )
            
        default:
            break
        }
    }
    
    private func executeJS(_ code: String) {
        webView?.evaluateJavaScript(code) { _, error in
            if let error = error {
                print("JS execution error: \(error)")
            }
        }
    }
    
    // MARK: - Real Send Code (Calls Real Telegram MTProto)
    public func sendCode(phoneNumber: String, dc: Int) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        self.currentPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.selectedDc = dc
        
        let escapedPhone = self.currentPhone
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        
        return await withCheckedContinuation { continuation in
            self.pendingSendCodeContinuation = continuation
            let js = "window.sendCode('\(escapedPhone)', \(self.apiId), '\(self.apiHash)', \(dc));"
            self.executeJS(js)
        }
    }
    
    // MARK: - Real Sign In (Validates Real Telegram Code)
    public func signIn(code: String, password: String? = nil) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let escapedCode = trimmedCode
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let escapedPhone = self.currentPhone
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            
        let pwdArg = password != nil ? "'\(password!.replacingOccurrences(of: "'", with: "\\'"))'" : "null"
        
        return await withCheckedContinuation { continuation in
            self.pendingSignInContinuation = continuation
            let js = "window.signIn('\(escapedPhone)', '\(escapedCode)', \(pwdArg));"
            self.executeJS(js)
        }
    }
    
    public func refreshStats() {
        executeJS("window.fetchUnreads();")
    }
    
    public func fetchUnreadStats() {
        refreshStats()
    }
    
    public func setPreset(_ preset: TelegramPreset) {
        self.apiId = preset.apiId
        self.apiHash = preset.apiHash
    }
    
    public func simulateIncomingNotification(chatTitle: String, sender: String, text: String, type: ChatType) {
        let item = NotificationItem(
            chatId: UUID().uuidString,
            chatTitle: chatTitle,
            senderName: sender,
            messageText: text,
            timestamp: Date(),
            chatType: type
        )
        
        withAnimation(.spring()) {
            self.notifications.insert(item, at: 0)
            var newStats = self.stats
            newStats.totalUnreadMessages += 1
            if newStats.totalUnreadChats == 0 { newStats.totalUnreadChats = 1 }
            switch type {
            case .private: newStats.privateChatsUnread += 1
            case .group: newStats.groupsUnread += 1
            case .channel: newStats.channelsUnread += 1
            }
            newStats.lastUpdated = Date()
            self.stats = newStats
        }
        
        SoundHapticManager.shared.playNotificationFeedback()
        LocalPushManager.shared.scheduleNotification(
            title: "\(chatTitle): \(sender)",
            body: text,
            badgeCount: self.stats.totalUnreadMessages
        )
        
        LiveActivityManager.shared.startOrUpdateLiveActivity(
            unreadCount: self.stats.totalUnreadMessages,
            lastSender: sender,
            lastMessage: text,
            chatTitle: chatTitle
        )
    }
    
    public func clearNotifications() {
        withAnimation {
            self.notifications.removeAll()
        }
    }
    
    public func resetCounters() {
        withAnimation {
            self.stats = UnreadStats()
            LocalPushManager.shared.updateBadge(count: 0)
        }
    }
    
    // MARK: - Safe Reconnect
    public func reconnect() {
        self.connectionState = .connecting
        self.isLoading = false
        self.errorMessage = nil
        let savedSession = UserDefaults.standard.string(forKey: "tg_saved_session") ?? ""
        let escapedSession = savedSession
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        executeJS("window.initTelegram(\(apiId), '\(apiHash)', '\(escapedSession)', \(selectedDc));")
        
        Task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            if self.connectionState == .connecting {
                self.connectionState = .disconnected
            }
        }
    }
    
    public func logout() {
        self.currentUser = nil
        self.connectionState = .disconnected
        self.isCodeSent = false
        self.requires2FA = false
        UserDefaults.standard.removeObject(forKey: "tg_saved_session")
        UserDefaults.standard.removeObject(forKey: "tg_saved_user_id")
        UserDefaults.standard.removeObject(forKey: "tg_saved_user_first_name")
        UserDefaults.standard.removeObject(forKey: "tg_saved_user_last_name")
        UserDefaults.standard.removeObject(forKey: "tg_saved_user_username")
        UserDefaults.standard.removeObject(forKey: "tg_saved_user_phone")
        LiveActivityManager.shared.endLiveActivity()
        executeJS("window.logOut();")
    }
}
