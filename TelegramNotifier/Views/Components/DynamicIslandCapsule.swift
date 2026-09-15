import SwiftUI

public struct DynamicIslandCapsule: View {
    @ObservedObject var client: TelegramClient
    
    public init(client: TelegramClient) {
        self.client = client
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            // Live Status Indicator Pulse
            HStack(spacing: 6) {
                ZStack {
                    if client.connectionState == .connected {
                        Circle()
                            .fill(Color.green.opacity(0.4))
                            .frame(width: 14, height: 14)
                            .scaleEffect(1.3)
                    }
                    Circle()
                        .fill(client.connectionState.statusColor)
                        .frame(width: 8, height: 8)
                }
                
                Text(client.connectionState.rawValue)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(client.connectionState == .connected ? .green : .gray)
            }
            
            Spacer()
            
            // Unread Pill Badge
            if client.stats.totalUnreadMessages > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("\(client.stats.totalUnreadMessages) новых")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.red.opacity(0.18))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                )
            }
            
            // Gateway / Wifi Symbol
            HStack(spacing: 3) {
                Image(systemName: "wifi")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(client.connectionState == .connected ? .green : .gray)
                Text(client.selectedDc == 2 ? "DC2" : "DC4")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 4)
        .frame(maxWidth: 340)
    }
}
