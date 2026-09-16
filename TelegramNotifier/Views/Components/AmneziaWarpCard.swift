import SwiftUI

public struct AmneziaWarpCard: View {
    @ObservedObject var vpn = AmneziaVPNManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Animated Shield Icon
                ZStack {
                    Circle()
                        .fill(vpn.isVpnActive ? Color.green.opacity(0.2) : Color.cyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    if vpn.isVpnActive {
                        Circle()
                            .stroke(Color.green.opacity(0.4), lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .scaleEffect(1.1)
                    }
                    
                    Image(systemName: vpn.isVpnActive ? "shield.fill" : "shield.slash.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(vpn.isVpnActive ? .green : .cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Amnezia Warp Tunnel")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(vpn.isVpnActive ? "АКТИВЕН" : "ВЫКЛ")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(vpn.isVpnActive ? .green : .gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(vpn.isVpnActive ? Color.green.opacity(0.18) : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    Text(vpn.isVpnActive ? "Обход блокировок Telegram в РФ включен" : "Нажмите для запуска без внешнего VPN")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Toggle Button
                Button(action: {
                    vpn.toggleVpn()
                }) {
                    if vpn.isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 40, height: 32)
                    } else {
                        Text(vpn.isVpnActive ? "Отключить" : "Запустить")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                vpn.isVpnActive
                                    ? LinearGradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: (vpn.isVpnActive ? Color.red : Color.cyan).opacity(0.35), radius: 6, x: 0, y: 3)
                    }
                }
            }
            
            // Stats & Actions Row
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(vpn.isVpnActive ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text("engage.cloudflareclient.com")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Copy Config Button
                Button(action: {
                    vpn.copyConfigToClipboard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: vpn.copiedToast ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                        Text(vpn.copiedToast ? "Скопировано!" : "Кфг Amnezia")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(vpn.copiedToast ? .green : .cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                
                if vpn.isVpnActive {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.yellow)
                        Text("\(vpn.pingMs) ms")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(vpn.isVpnActive ? Color.green.opacity(0.35) : Color.cyan.opacity(0.2), lineWidth: 1.2)
        )
    }
}

