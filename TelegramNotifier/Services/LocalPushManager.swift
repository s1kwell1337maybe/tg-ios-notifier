import Foundation
import UserNotifications
import UIKit

public final class LocalPushManager {
    public static let shared = LocalPushManager()
    
    private init() {}
    
    public func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    public func scheduleNotification(title: String, body: String, badgeCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💬 \(title)"
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: badgeCount)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule local notification: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badgeCount
        }
    }
    
    public func updateBadge(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = max(0, count)
        }
    }
}
