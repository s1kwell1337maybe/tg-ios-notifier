import SwiftUI

public struct SettingsView: View {
    @ObservedObject var client: TelegramClient
    @Environment(\.dismiss) private var dismiss
    
    @State private var soundEnabled: Bool = SoundHapticManager.shared.getSoundEnabled()
    @State private var hapticsEnabled: Bool = SoundHapticManager.shared.getHapticsEnabled()
    @State private var apiIdInput: String = ""
    @State private var apiHashInput: String = ""
    @State private var showSavedAlert: Bool = false
    
    public init(client: TelegramClient) {
        self.client = client
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.07, blue: 0.12)
                    .ignoresSafeArea()
                
                List {
                    // Notifications Section
                    Section(header: Text("УВЕДОМЛЕНИЯ И ЗВУК").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)) {
                        Toggle(isOn: $soundEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Звук уведомлений iOS")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .onChange(of: soundEnabled) { val in
                            SoundHapticManager.shared.setSound(enabled: val)
                            if val { SoundHapticManager.shared.playNotificationFeedback() }
                        }
                        
                        Toggle(isOn: $hapticsEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                Text("Вибрация (Taptic Engine)")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .onChange(of: hapticsEnabled) { val in
                            SoundHapticManager.shared.setHaptics(enabled: val)
                            if val { SoundHapticManager.shared.playNotificationFeedback() }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                    
                    // Gateway DC Section
                    Section(header: Text("ШЛЮЗ СЕРВЕРОВ TELEGRAM").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)) {
                        HStack {
                            Text("Активный Дата-центр")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(client.selectedDc == 2 ? "🇷🇺 DC 2 (Россия / СНГ — Без VPN)" : "🌍 DC 4 (Европа)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                    
                    // Telegram API Presets
                    Section(header: Text("ПРЕСЕТЫ TELEGRAM API").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)) {
                        ForEach(client.presets) { preset in
                            Button(action: {
                                client.setPreset(preset)
                                SoundHapticManager.shared.playSuccessFeedback()
                                showSavedAlert = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("API ID: \(preset.apiId)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if client.apiId == preset.apiId {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                    
                    // Sideload info
                    Section(header: Text("СБОРКА ДЛЯ IPHONE").font(.system(size: 11, weight: .bold)).foregroundColor(.gray)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Поддерживается TrollStore, Sideloadly, AltStore, Scarlet")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("• Bundle ID: com.telegram.notifier")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                    
                    // Reset Section
                    Section {
                        Button(action: {
                            client.resetCounters()
                            SoundHapticManager.shared.playSuccessFeedback()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Обнулить все счетчики")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(Color.red.opacity(0.12))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}
