import SwiftUI

public struct LoginView: View {
    @ObservedObject var client: TelegramClient
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber: String = "+7 "
    @State private var otpCode: String = ""
    @State private var password2FA: String = ""
    @State private var step: LoginStep = .phone
    @State private var showAdvanced: Bool = false
    @State private var selectedDc: Int = 2
    
    public enum LoginStep {
        case phone
        case code
        case password
    }
    
    public init(client: TelegramClient) {
        self.client = client
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.07, blue: 0.12),
                        Color(red: 0.08, green: 0.12, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon & Title
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                                    )
                                
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.top, 10)
                            
                            Text("Авторизация в Telegram")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Прямое защищенное подключение по протоколу MTProto")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Error Alert Banner
                        if let error = client.errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.red.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
                            )
                        }
                        
                        // Steps
                        if client.currentUser != nil {
                            loggedInView
                        } else if client.requires2FA || step == .password {
                            passwordStepView
                        } else if client.isCodeSent || step == .code {
                            codeStepView
                        } else {
                            phoneStepView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Logged In State
    private var loggedInView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 68, height: 68)
                Text(client.currentUser?.initial ?? "U")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(client.currentUser?.displayName ?? "Telegram User")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(client.currentUser?.displayTag ?? "")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.cyan)
            
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Авторизован в Telegram MTProto")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())
            
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Закрыть")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Button(action: {
                    client.logout()
                    step = .phone
                }) {
                    Text("Выйти из аккаунта")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Phone Step
    private var phoneStepView: some View {
        VStack(spacing: 20) {
            // DC Gateway Selector (Direct DC 2 Russia)
            VStack(alignment: .leading, spacing: 8) {
                Text("ШЛЮЗ ПОДКЛЮЧЕНИЯ (БЕЗ VPN)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    Button(action: { selectedDc = 2; SoundHapticManager.shared.playLightImpact() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe.europe.africa.fill")
                            Text("🇷🇺 Россия (DC 2)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(selectedDc == 2 ? .cyan : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedDc == 2 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedDc == 2 ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    Button(action: { selectedDc = 4; SoundHapticManager.shared.playLightImpact() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe.americas.fill")
                            Text("🌍 Мир (DC 4)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(selectedDc == 4 ? .cyan : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedDc == 4 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedDc == 4 ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Phone Input Field
            VStack(alignment: .leading, spacing: 8) {
                Text("НОМЕР ТЕЛЕФОНА")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    
                    TextField("+7 925 043 13 39", text: $phoneNumber)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.phonePad)
                }
                .padding(14)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                
                Text("Официальный код безопасности придет в приложение Telegram")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            // Send Code Button
            Button(action: {
                Task {
                    let success = await client.sendCode(phoneNumber: phoneNumber, dc: selectedDc)
                    if success {
                        withAnimation(.spring()) {
                            step = .code
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if client.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Получить код в Telegram")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.67, blue: 0.93), Color(red: 0.13, green: 0.58, blue: 0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .disabled(client.isLoading)
        }
    }
    
    // MARK: - Code Step
    private var codeStepView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("КОД ИЗ TELEGRAM")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    withAnimation {
                        client.isCodeSent = false
                        step = .phone
                    }
                }) {
                    Text("Изменить номер (\(phoneNumber))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            
            // OTP Code Input
            TextField("12345", text: $otpCode)
                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding(16)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                )
            
            Text("Введите 5-значный проверочный код. Если код неверен — вход будет отклонен.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Confirm Button
            Button(action: {
                Task {
                    let success = await client.signIn(code: otpCode)
                    if success {
                        dismiss()
                    } else if client.requires2FA {
                        withAnimation {
                            step = .password
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if client.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Подтвердить и войти")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color(red: 0.15, green: 0.75, blue: 0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.green.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .disabled(client.isLoading)
        }
    }
    
    // MARK: - Password Step
    private var passwordStepView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ОБЛАЧНЫЙ ПАРОЛЬ 2FA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                SecureField("Ваш пароль 2-этапной защиты", text: $password2FA)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            
            Button(action: {
                Task {
                    let success = await client.signIn(code: otpCode, password: password2FA)
                    if success {
                        dismiss()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if client.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Войти с паролем")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(client.isLoading)
        }
    }
}
