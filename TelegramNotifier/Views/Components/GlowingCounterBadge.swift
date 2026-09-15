import SwiftUI

public struct GlowingCounterBadge: View {
    let unreadCount: Int
    let totalChats: Int
    let lastUpdated: Date
    let onTestTap: () -> Void
    let onLoginTap: () -> Void
    let isLoggedIn: Bool
    
    @State private var isPulsing = false
    
    public init(unreadCount: Int, totalChats: Int, lastUpdated: Date, isLoggedIn: Bool, onTestTap: @escaping () -> Void, onLoginTap: @escaping () -> Void) {
        self.unreadCount = unreadCount
        self.totalChats = totalChats
        self.lastUpdated = lastUpdated
        self.isLoggedIn = isLoggedIn
        self.onTestTap = onTestTap
        self.onLoginTap = onLoginTap
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header Pill
            HStack(spacing: 6) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.35))
                Text("Уведомления Telegram")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            
            // Giant Neon Glowing Badge
            ZStack {
                // Outer Glow Blur
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.6), Color.pink.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: isPulsing ? 20 : 12)
                    .scaleEffect(isPulsing ? 1.08 : 1.0)
                
                // Solid Badge Body
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.25, blue: 0.25),
                                Color(red: 0.88, green: 0.12, blue: 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 116, height: 116)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: Color.red.opacity(0.4), radius: 15, x: 0, y: 8)
                
                // Number
                Text("\(unreadCount)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }
            .padding(.vertical, 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            
            // Subtitle status
            VStack(spacing: 3) {
                Text(unreadCount == 0 ? "Все сообщения прочитаны 🎉" : unreadCount == 1 ? "1 новое сообщение" : "\(unreadCount) непрочитанных сообщений в \(totalChats) чатах")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Обновлено: \(lastUpdated, style: .time)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: onTestTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("Тест уведомления")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                
                if !isLoggedIn {
                    Button(action: onLoginTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Подключить Telegram")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.16, green: 0.67, blue: 0.93), Color(red: 0.13, green: 0.58, blue: 0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
    }
}
