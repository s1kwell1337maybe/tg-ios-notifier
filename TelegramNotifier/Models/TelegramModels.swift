import Foundation
import SwiftUI

public enum ConnectionState: String {
    case disconnected = "Отключено"
    case connecting = "Подключение..."
    case connected = "MTProto Live"
    case error = "Ошибка сети"
    
    public var statusColor: Color {
        switch self {
        case .connected: return Color(red: 0.2, green: 0.85, blue: 0.4)
        case .connecting: return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .disconnected: return Color(red: 0.95, green: 0.3, blue: 0.3)
        case .error: return Color(red: 0.95, green: 0.2, blue: 0.2)
        }
    }
}

public enum ChatType: String, Codable {
    case `private` = "Личный чат"
    case group = "Группа"
    case channel = "Канал"
    
    public var sfSymbol: String {
        switch self {
        case .private: return "person.fill"
        case .group: return "person.2.fill"
        case .channel: return "antenna.radiowaves.left.and.right"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .private: return Color(red: 0.15, green: 0.65, blue: 0.95)
        case .group: return Color(red: 0.4, green: 0.45, blue: 0.95)
        case .channel: return Color(red: 1.0, green: 0.6, blue: 0.15)
        }
    }
}

public struct TelegramUser: Identifiable, Codable {
    public let id: String
    public var firstName: String
    public var lastName: String?
    public var username: String?
    public var phone: String?
    
    public var displayName: String {
        if let last = lastName, !last.isEmpty {
            return "\(firstName) \(last)"
        }
        return firstName
    }
    
    public var displayTag: String {
        if let u = username, !u.isEmpty {
            return "@\(u)"
        }
        return phone ?? "Telegram Account"
    }
    
    public var initial: String {
        return String(firstName.prefix(1)).uppercased()
    }
}

public struct UnreadStats: Codable {
    public var totalUnreadMessages: Int = 0
    public var totalUnreadChats: Int = 0
    public var privateChatsUnread: Int = 0
    public var groupsUnread: Int = 0
    public var channelsUnread: Int = 0
    public var mentionsCount: Int = 0
    public var lastUpdated: Date = Date()
    
    public init() {}
}

public struct NotificationItem: Identifiable, Codable {
    public let id: String
    public let chatId: String
    public let chatTitle: String
    public let senderName: String
    public let messageText: String
    public let timestamp: Date
    public let chatType: ChatType
    public var isRead: Bool = false
    
    public init(id: String = UUID().uuidString, chatId: String, chatTitle: String, senderName: String, messageText: String, timestamp: Date = Date(), chatType: ChatType, isRead: Bool = false) {
        self.id = id
        self.chatId = chatId
        self.chatTitle = chatTitle
        self.senderName = senderName
        self.messageText = messageText
        self.timestamp = timestamp
        self.chatType = chatType
        self.isRead = isRead
    }
    
    public var formattedTime: String {
        let diff = Int(Date().timeIntervalSince(timestamp))
        if diff < 10 { return "Только что" }
        if diff < 60 { return "\(diff) сек назад" }
        let mins = diff / 60
        if mins < 60 { return "\(mins) мин назад" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

public struct TelegramPreset: Identifiable {
    public let id = UUID()
    public let name: String
    public let apiId: Int
    public let apiHash: String
}
