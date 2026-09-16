import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()
    
    private init() {}
    
    public func startOrUpdateLiveActivity(
        unreadCount: Int,
        lastSender: String,
        lastMessage: String,
        chatTitle: String = "Telegram"
    ) {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            
            let state = TelegramLiveActivityAttributes.ContentState(
                unreadCount: unreadCount,
                lastSender: lastSender,
                lastMessage: lastMessage,
                chatTitle: chatTitle,
                isConnected: true,
                timestamp: Date()
            )
            
            // Check for existing active activity
            if let existingActivity = Activity<TelegramLiveActivityAttributes>.activities.first {
                Task {
                    await existingActivity.update(using: state)
                }
            } else {
                do {
                    let attributes = TelegramLiveActivityAttributes(accountName: "Telegram Notifier")
                    _ = try Activity<TelegramLiveActivityAttributes>.request(
                        attributes: attributes,
                        contentState: state,
                        pushType: nil
                    )
                } catch {
                    print("Failed to start Live Activity: \(error)")
                }
            }
        }
        #endif
    }
    
    public func endLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            for activity in Activity<TelegramLiveActivityAttributes>.activities {
                Task {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
        #endif
    }
}
