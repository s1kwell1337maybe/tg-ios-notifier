import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Hardware Dynamic Island & Lock Screen Live Activity Attributes
#if canImport(ActivityKit)
public struct TelegramLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var unreadCount: Int
        public var lastSender: String
        public var lastMessage: String
        public var chatTitle: String
        public var isConnected: Bool
        public var timestamp: Date
        
        public init(
            unreadCount: Int,
            lastSender: String,
            lastMessage: String,
            chatTitle: String = "Telegram",
            isConnected: Bool = true,
            timestamp: Date = Date()
        ) {
            self.unreadCount = unreadCount
            self.lastSender = lastSender
            self.lastMessage = lastMessage
            self.chatTitle = chatTitle
            self.isConnected = isConnected
            self.timestamp = timestamp
        }
    }

    public var accountName: String
    
    public init(accountName: String = "Telegram") {
        self.accountName = accountName
    }
}
#endif
