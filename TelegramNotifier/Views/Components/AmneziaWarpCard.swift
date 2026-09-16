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
                    
                    Text(vpn.statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(vpn.isVpnActive ? .green.opacity(0.9) : .gray)
                        .lineLimit(1)
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
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
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Action Buttons Row (Import to Amnezia App, Add to iOS Settings, Copy .conf)
            HStack(spacing: 8) {
                // Share & Import directly into AmneziaWG / WireGuard App
                Button(action: {
                    vpn.exportAndShareConfig()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text("Импорт в AmneziaWG")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                
                // Install to iOS Settings
                Button(action: {
                    vpn.installVPNConfiguration()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("В настройки iOS")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                
                Spacer()
                
                // Copy Config Button
                Button(action: {
                    vpn.copyConfigToClipboard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: vpn.copiedToast ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                        Text(vpn.copiedToast ? "Скопировано!" : ".conf")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(vpn.copiedToast ? .green : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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


