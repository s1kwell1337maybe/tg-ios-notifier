import SwiftUI

public struct NotificationRow: View {
    let item: NotificationItem
    let onPlaySound: () -> Void
    
    public init(item: NotificationItem, onPlaySound: @escaping () -> Void) {
        self.item = item
        self.onPlaySound = onPlaySound
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar Initial Circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Text(String(item.senderName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        Text(item.senderName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if item.chatTitle != item.senderName {
                            Text("в \(item.chatTitle)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.formattedTime)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text(item.messageText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Bottom Type Tag & Sound Button
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: item.chatType.sfSymbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(item.chatType.tintColor)
                        Text(item.chatType.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(item.chatType.tintColor)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(item.chatType.tintColor.opacity(0.14))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button(action: onPlaySound) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .padding(4)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
