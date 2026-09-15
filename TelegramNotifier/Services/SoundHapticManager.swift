import Foundation
import UIKit
import AudioToolbox
import AVFoundation

public final class SoundHapticManager {
    public static let shared = SoundHapticManager()
    
    private var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "tg_sound_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "tg_sound_enabled") }
    }
    
    private var isHapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "tg_haptics_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "tg_haptics_enabled") }
    }
    
    private init() {}
    
    public func setSound(enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    public func getSoundEnabled() -> Bool {
        return isSoundEnabled
    }
    
    public func setHaptics(enabled: Bool) {
        isHapticsEnabled = enabled
    }
    
    public func getHapticsEnabled() -> Bool {
        return isHapticsEnabled
    }
    
    // Play iOS Tri-Tone / Message Chime and Heavy Taptic Feedback
    public func playNotificationFeedback() {
        if isHapticsEnabled {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.prepare()
            impact.impactOccurred()
        }
        
        if isSoundEnabled {
            // iOS System SMS/Message chime sound ID 1007
            AudioServicesPlaySystemSound(1007)
        }
    }
    
    public func playSuccessFeedback() {
        if isHapticsEnabled {
            let notification = UINotificationFeedbackGenerator()
            notification.prepare()
            notification.notificationOccurred(.success)
        }
        if isSoundEnabled {
            AudioServicesPlaySystemSound(1057) // PIN tap sound
        }
    }
    
    public func playErrorFeedback() {
        if isHapticsEnabled {
            let notification = UINotificationFeedbackGenerator()
            notification.prepare()
            notification.notificationOccurred(.error)
        }
        if isSoundEnabled {
            AudioServicesPlaySystemSound(1053) // Error beep
        }
    }
    
    public func playLightImpact() {
        if isHapticsEnabled {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
        }
    }
}
