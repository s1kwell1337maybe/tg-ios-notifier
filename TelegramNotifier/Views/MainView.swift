import SwiftUI

public struct MainView: View {
    @StateObject private var client = TelegramClient.shared
    @State private var showLoginSheet: Bool = false
    @State private var showSettingsSheet: Bool = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700 || (horizontalSizeClass == .regular && geometry.size.width > geometry.size.height)
            
            ZStack {
                // Dark iOS Premium Background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.06, blue: 0.11),
                        Color(red: 0.07, green: 0.10, blue: 0.17),
                        Color(red: 0.03, green: 0.05, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Background Radial Glow Orbs
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.12))
                        .frame(width: geometry.size.width * 0.6)
                        .blur(radius: 70)
                        .offset(x: -geometry.size.width * 0.25, y: -geometry.size.height * 0.2)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.10))
                        .frame(width: geometry.size.width * 0.6)
                        .blur(radius: 80)
                        .offset(x: geometry.size.width * 0.25, y: geometry.size.height * 0.2)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Dynamic Island Capsule (Floating)
                    DynamicIslandCapsule(client: client)
                        .padding(.top, 8)
                        .padding(.bottom, 10)
                    
                    if isWide {
                        // iPad & Landscape 2-Column Dashboard Layout
                        HStack(alignment: .top, spacing: 20) {
                            // Left Column (Controls, Hero Badge, Categories)
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 16) {
                                    profileHeaderBar
                                    
                                    GlowingCounterBadge(
                                        unreadCount: client.stats.totalUnreadMessages,
                                        totalChats: client.stats.totalUnreadChats,
                                        lastUpdated: client.stats.lastUpdated,
                                        isLoggedIn: client.currentUser != nil,
                                        onTestTap: triggerTestNotification,
                                        onLoginTap: { showLoginSheet = true }
                                    )
                                    
                                    categoriesGrid
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 30)
                            }
                            .frame(maxWidth: geometry.size.width * 0.48)
                            
                            // Right Column (Live Notification Feed)
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 16) {
                                    notificationsFeedSection
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 30)
                            }
                        }
                    } else {
                        // iPhone / Portrait Single Column Layout
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                profileHeaderBar
                                
                                GlowingCounterBadge(
                                    unreadCount: client.stats.totalUnreadMessages,
                                    totalChats: client.stats.totalUnreadChats,
                                    lastUpdated: client.stats.lastUpdated,
                                    isLoggedIn: client.currentUser != nil,
                                    onTestTap: triggerTestNotification,
                                    onLoginTap: { showLoginSheet = true }
                                )
                                
                                categoriesGrid
                                
                                notificationsFeedSection
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .onAppear {
            LocalPushManager.shared.requestPermissions()
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView(client: client)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(client: client)
        }
    }
    
    // MARK: - Profile Header Bar
    private var profileHeaderBar: some View {
        HStack {
            if let user = client.currentUser {
                Button(action: { showLoginSheet = true }) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 38, height: 38)
                            Text(user.initial)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(user.displayName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.cyan)
                            }
                            Text(user.displayTag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                Button(action: { showLoginSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Войти через Telegram")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }
            
            Spacer()
            
            // Refresh & Settings Buttons
            HStack(spacing: 8) {
                if client.currentUser != nil {
                    Button(action: {
                        SoundHapticManager.shared.playLightImpact()
                        client.refreshStats()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                
                Button(action: { showSettingsSheet = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    // MARK: - Categories Grid
    private var categoriesGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                CategoryStatCard(
                    title: "Личные чаты",
                    subtitle: "Диалоги",
                    count: client.stats.privateChatsUnread,
                    iconName: "person.fill",
                    tintColor: Color(red: 0.15, green: 0.65, blue: 0.95)
                )
                
                CategoryStatCard(
                    title: "Группы",
                    subtitle: "Беседы",
                    count: client.stats.groupsUnread,
                    iconName: "person.2.fill",
                    tintColor: Color(red: 0.45, green: 0.45, blue: 0.95)
                )
            }
            
            HStack(spacing: 10) {
                CategoryStatCard(
                    title: "Каналы",
                    subtitle: "Подписки",
                    count: client.stats.channelsUnread,
                    iconName: "antenna.radiowaves.left.and.right",
                    tintColor: Color(red: 1.0, green: 0.65, blue: 0.15)
                )
                
                CategoryStatCard(
                    title: "Упоминания",
                    subtitle: "Ответы",
                    count: client.stats.mentionsCount,
                    iconName: "at",
                    tintColor: Color(red: 0.95, green: 0.35, blue: 0.45)
                )
            }
        }
    }
    
    // MARK: - Notifications Feed Section
    private var notificationsFeedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("Лента уведомлений")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(client.notifications.count)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                if !client.notifications.isEmpty {
                    Button(action: { client.clearNotifications() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Очистить")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red.opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            if client.notifications.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Пока нет новых уведомлений")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("При получении сообщений они появятся здесь в реальном времени")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(client.notifications) { item in
                        NotificationRow(item: item) {
                            SoundHapticManager.shared.playNotificationFeedback()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Simulation Trigger
    private func triggerTestNotification() {
        let demos: [(title: String, sender: String, text: String, type: ChatType)] = [
            ("Павел Дуров", "Pavel Durov", "Привет! Проверяем как работает Telegram Notifier под iOS 🚀", .private),
            ("iOS & Swift Разработка", "Алексей", "Сборка .ipa готова и протестирована на Swift/SwiftUI!", .group),
            ("Telegram Info RU", "Telegram Info", "🔥 Рекордный трафик в Telegram. Все службы работают в штатном режиме.", .channel),
            ("Анна", "Анна", "Привет! Ты увидел уведомление? Ответь в телеграмме 😊", .private)
        ]
        
        let random = demos.randomElement()!
        client.simulateIncomingNotification(
            chatTitle: random.title,
            sender: random.sender,
            text: random.text,
            type: random.type
        )
    }
}
