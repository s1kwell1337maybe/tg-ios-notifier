import SwiftUI

public struct CategoryStatCard: View {
    let title: String
    let subtitle: String
    let count: Int
    let iconName: String
    let tintColor: Color
    
    public init(title: String, subtitle: String, count: Int, iconName: String, tintColor: Color) {
        self.title = title
        self.subtitle = subtitle
        self.count = count
        self.iconName = iconName
        self.tintColor = tintColor
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Icon capsule
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tintColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(tintColor.opacity(0.35), lineWidth: 1)
                    )
                
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(tintColor)
            }
            
            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Badge Counter Pill
            Text("\(count)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(count > 0 ? tintColor : .gray.opacity(0.6))
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(count > 0 ? tintColor.opacity(0.2) : Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(count > 0 ? tintColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
