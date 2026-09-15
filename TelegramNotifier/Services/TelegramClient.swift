import Foundation
import WebKit
import SwiftUI
import Combine

// MARK: - Real MTProto 2.0 Native Bridge Client
// Runs official Telegram MTProto Web engine locally inside native iOS WebKit WKWebView
// Communicates with Telegram DC 2 (Russia/CIS) & DC 4 over TLS WSS without VPN.

@MainActor
public final class TelegramClient: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {
    public static let shared = TelegramClient()
    
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var currentUser: TelegramUser? = nil
    @Published public var stats: UnreadStats = UnreadStats()
    @Published public var notifications: [NotificationItem] = []
    
    @Published public var selectedDc: Int = 2
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
        setupEngine()
    }
    
    private func setupEngine() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "tgNativeBridge")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        self.webView = wv
        
        // HTML + JavaScript MTProto Engine running locally inside native app
        let engineHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <script src="https://cdn.jsdelivr.net/npm/telegram@2.22.2/browser/index.js"></script>
        </head>
        <body>
            <script>
                window.client = null;
                window.phoneCodeHash = '';
                
                function sendToNative(type, payload) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.tgNativeBridge) {
                        window.webkit.messageHandlers.tgNativeBridge.postMessage({ type: type, payload: payload });
                    }
                }
                
                window.initTelegram = async function(apiId, apiHash, sessionStr, dcId) {
                    try {
                        const { TelegramClient } = telegram;
                        const { StringSession } = telegram.sessions;
                        
                        const session = new StringSession(sessionStr || '');
                        if (dcId === 2) {
                            session.setDC(2, 'venus.web.telegram.org', 443);
                        } else {
                            session.setDC(4, 'vesta.web.telegram.org', 443);
                        }
                        
                        window.client = new TelegramClient(session, parseInt(apiId), apiHash, {
                            connectionRetries: 5,
                            useWSS: true,
                            deviceModel: 'Apple iPad / iPhone (Native)',
                            systemVersion: 'iOS 18.0',
                            appVersion: '1.0.0',
                            langCode: 'ru',
                            systemLangCode: 'ru'
                        });
                        
                        await window.client.connect();
                        sendToNative('CONNECTED', { dc: dcId });
                        
                        const isAuth = await window.client.checkAuthorization();
                        if (isAuth) {
                            const me = await window.client.getMe();
                            sendToNative('AUTH_SUCCESS', {
                                id: String(me.id),
                                firstName: me.firstName || 'User',
                                lastName: me.lastName || '',
                                username: me.username || '',
                                phone: me.phone || '',
                                session: window.client.session.save()
                            });
                            startUpdateListener();
                            fetchUnreads();
                        }
                    } catch (e) {
                        sendToNative('ERROR', { message: e.message || String(e) });
                    }
                };
                
                window.sendCode = async function(phone, apiId, apiHash, dcId) {
                    try {
                        await window.initTelegram(apiId, apiHash, '', dcId);
                        const res = await window.client.sendCode({
                            apiId: parseInt(apiId),
                            apiHash: apiHash
                        }, phone);
                        
                        window.phoneCodeHash = res.phoneCodeHash;
                        sendToNative('CODE_SENT', { phoneCodeHash: res.phoneCodeHash });
                    } catch (e) {
                        sendToNative('SEND_CODE_ERROR', { message: e.message || String(e) });
                    }
                };
                
                window.signIn = async function(phone, code, password, apiId, apiHash) {
                    try {
                        if (password) {
                            await window.client.signInWithPassword({
                                apiId: parseInt(apiId),
                                apiHash: apiHash
                            }, {
                                password: async () => password,
                                onError: (err) => console.error(err)
                            });
                        } else {
                            await window.client.invoke(new telegram.Api.auth.SignIn({
                                phoneNumber: phone,
                                phoneCodeHash: window.phoneCodeHash,
                                phoneCode: code.trim()
                            }));
                        }
                        
                        const sessionStr = window.client.session.save();
                        const me = await window.client.getMe();
                        sendToNative('AUTH_SUCCESS', {
                            id: String(me.id),
                            firstName: me.firstName || 'User',
                            lastName: me.lastName || '',
                            username: me.username || '',
                            phone: me.phone || phone,
                            session: sessionStr
                        });
                        startUpdateListener();
                        fetchUnreads();
                    } catch (e) {
                        const msg = e.message || String(e);
                        if (msg.includes('SESSION_PASSWORD_NEEDED') || msg.includes('2FA')) {
                            sendToNative('2FA_REQUIRED', {});
                        } else {
                            sendToNative('SIGN_IN_ERROR', { message: msg });
                        }
                    }
                };
                
                function startUpdateListener() {
                    if (!window.client) return;
                    window.client.addEventHandler(async (event) => {
                        const message = event.message;
                        if (!message || message.out) return;
                        
                        let chatTitle = 'Чат Telegram';
                        let senderName = 'Пользователь';
                        let chatType = 'private';
                        
                        try {
                            const chat = await message.getChat();
                            if (chat) {
                                chatTitle = chat.title || chat.firstName || 'Telegram';
                                if (chat.className === 'Channel') chatType = chat.broadcast ? 'channel' : 'group';
                                else if (chat.className === 'Chat') chatType = 'group';
                            }
                        } catch(e) {}
                        
                        try {
                            const sender = await message.getSender();
                            if (sender) senderName = sender.firstName || sender.title || senderName;
                        } catch(e) {}
                        
                        sendToNative('NEW_MESSAGE', {
                            id: String(message.id),
                            chatId: String(message.chatId || message.peerId),
                            chatTitle: chatTitle,
                            senderName: senderName,
                            messageText: message.text || '📎 Новое вложение',
                            chatType: chatType
                        });
                        
                        fetchUnreads();
                    }, new telegram.events.NewMessage({}));
                }
                
                window.fetchUnreads = async function() {
                    try {
                        if (!window.client) return;
                        const dialogs = await window.client.getDialogs({ limit: 100 });
                        let total = 0, chats = 0, priv = 0, grp = 0, chn = 0, mentions = 0;
                        for (const d of dialogs) {
                            const unread = d.unreadCount || 0;
                            mentions += d.unreadMentionsCount || 0;
                            if (unread > 0) {
                                chats++;
                                total += unread;
                                if (d.isUser) priv += unread;
                                else if (d.isGroup) grp += unread;
                                else if (d.isChannel) chn += unread;
                            }
                        }
                        sendToNative('UNREAD_STATS', {
                            totalUnreadMessages: total,
                            totalUnreadChats: chats,
                            privateChatsUnread: priv,
                            groupsUnread: grp,
                            channelsUnread: chn,
                            mentionsCount: mentions
                        });
                    } catch(e) {}
                };
                
                sendToNative('ENGINE_READY', {});
            </script>
        </body>
        </html>
        """
        
        wv.loadHTMLString(engineHTML, baseURL: URL(string: "https://web.telegram.org"))
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
                executeJS("window.initTelegram(\(apiId), '\(apiHash)', '\(savedSession)', \(selectedDc));")
            }
            
        case "CONNECTED":
            self.connectionState = .connected
            
        case "CODE_SENT":
            self.isLoading = false
            self.isCodeSent = true
            self.errorMessage = nil
            SoundHapticManager.shared.playSuccessFeedback()
            self.pendingSendCodeContinuation?.resume(returning: true)
            self.pendingSendCodeContinuation = nil
            
        case "SEND_CODE_ERROR":
            self.isLoading = false
            let msg = payload["message"] as? String ?? "Ошибка отправки кода"
            if msg.contains("PHONE_NUMBER_INVALID") {
                self.errorMessage = "Неверный формат номера телефона (пример: +79250431339)"
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
            }
            
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
                self.errorMessage = "Неверный код подтверждения (PHONE_CODE_INVALID). Проверьте сообщение в Telegram"
            } else if msg.contains("PHONE_CODE_EXPIRED") {
                self.errorMessage = "Срок действия кода истек. Запросите код заново"
            } else {
                self.errorMessage = "Ошибка авторизации: \(msg)"
            }
            SoundHapticManager.shared.playErrorFeedback()
            self.pendingSignInContinuation?.resume(returning: false)
            self.pendingSignInContinuation = nil
            
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
        
        return await withCheckedContinuation { continuation in
            self.pendingSendCodeContinuation = continuation
            let js = "window.sendCode('\(self.currentPhone)', \(self.apiId), '\(self.apiHash)', \(dc));"
            self.executeJS(js)
        }
    }
    
    // MARK: - Real Sign In (Validates Real Telegram Code)
    public func signIn(code: String, password: String? = nil) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let pwdEscaped = password?.replacingOccurrences(of: "'", with: "\\'") ?? ""
        
        return await withCheckedContinuation { continuation in
            self.pendingSignInContinuation = continuation
            let js = "window.signIn('\(self.currentPhone)', '\(trimmedCode)', \(password == nil ? "null" : "'\(pwdEscaped)'"), \(self.apiId), '\(self.apiHash)');"
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
    
    public func logout() {
        self.currentUser = nil
        self.connectionState = .disconnected
        self.isCodeSent = false
        self.requires2FA = false
        UserDefaults.standard.removeObject(forKey: "tg_saved_session")
        executeJS("window.client = null;")
    }
}
