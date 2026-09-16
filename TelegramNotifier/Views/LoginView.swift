import SwiftUI

// MARK: - Phone Number Formatter (+7 925 043 1339)
public struct PhoneFormatter {
    public static func format(_ raw: String) -> String {
        // Strip everything except digits and +
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return "+7 " }
        
        var d = digits
        if d.hasPrefix("8") && d.count > 1 {
            d = "7" + d.dropFirst()
        } else if !d.hasPrefix("7") && !d.hasPrefix("1") && !d.hasPrefix("3") && !d.hasPrefix("4") && !d.hasPrefix("9") {
            d = "7" + d
        }
        
        if d.hasPrefix("7") {
            let number = String(d.dropFirst()) // digits after 7
            var res = "+7"
            if !number.isEmpty {
                let p1 = String(number.prefix(3))
                res += " " + p1
            }
            if number.count > 3 {
                let p2 = String(number.dropFirst(3).prefix(3))
                res += " " + p2
            }
            if number.count > 6 {
                let p3 = String(number.dropFirst(6).prefix(4))
                res += " " + p3
            }
            return res
        } else {
            // General international format: +XXX XXX XXXX
            var res = "+"
            for (i, char) in d.enumerated() {
                if (i == 1 && d.count > 1) || (i == 4 && d.count > 4) || (i == 7 && d.count > 7) || (i == 10 && d.count > 10) {
                    res += " "
                }
                res.append(char)
            }
            return res
        }
    }
    
    public static func cleanDigits(_ formatted: String) -> String {
        let digits = formatted.filter { $0.isNumber }
        if digits.hasPrefix("8") && digits.count == 11 {
            return "+7" + digits.dropFirst()
        }
        if !digits.hasPrefix("+") {
            return "+" + digits
        }
        return digits
    }
    
    public static func flagForNumber(_ formatted: String) -> String {
        let digits = formatted.filter { $0.isNumber }
        if digits.hasPrefix("7") { return "🇷🇺" }
        if digits.hasPrefix("1") { return "🇺🇸" }
        if digits.hasPrefix("380") { return "🇺🇦" }
        if digits.hasPrefix("375") { return "🇧🇾" }
        if digits.hasPrefix("998") { return "🇺🇿" }
        if digits.hasPrefix("77") { return "🇰🇿" }
        if digits.hasPrefix("44") { return "🇬🇧" }
        if digits.hasPrefix("49") { return "🇩🇪" }
        return "🌍"
    }
}

public struct LoginView: View {
    @ObservedObject var client: TelegramClient
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber: String = "+7 925 043 1339"
    @State private var otpCode: String = ""
    @State private var password2FA: String = ""
    @State private var step: LoginStep = .phone
    @State private var selectedDc: Int = 4
    
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
                // Background Deep Space Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.06, blue: 0.11),
                        Color(red: 0.07, green: 0.11, blue: 0.17)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Badge & Title
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
                                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
                                    )
                                
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.top, 10)
                            
                            Text("Авторизация в Telegram")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Официальное подключение MTProto к серверам Telegram")
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
                        
                        // Content by Step
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
                Text("Подключен к Telegram MTProto (DC \(client.selectedDc))")
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
            // DC Gateway Selector (DC 4 Recommended & DC 2)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ШЛЮЗ СЕРВЕРА TELEGRAM")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("⚡ Авто-миграция")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                
                HStack(spacing: 10) {
                    // DC 4 Button (Default / Recommended)
                    Button(action: {
                        selectedDc = 4
                        client.selectedDc = 4
                        SoundHapticManager.shared.playLightImpact()
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "globe.americas.fill")
                                Text("🌍 DC 4 (Мир)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            Text("Рекомендуется")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(selectedDc == 4 ? .cyan : .gray.opacity(0.8))
                        }
                        .foregroundColor(selectedDc == 4 ? .cyan : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedDc == 4 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedDc == 4 ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                    }
                    
                    // DC 2 Button (Russia / CIS)
                    Button(action: {
                        selectedDc = 2
                        client.selectedDc = 2
                        SoundHapticManager.shared.playLightImpact()
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "globe.europe.africa.fill")
                                Text("🇷🇺 DC 2 (РФ)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            Text("Шлюз Москва")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(selectedDc == 2 ? .cyan : .gray.opacity(0.8))
                        }
                        .foregroundColor(selectedDc == 2 ? .cyan : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedDc == 2 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedDc == 2 ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                    }
                }
            }
            
            // Beautiful Formatted Phone Input Field
            VStack(alignment: .leading, spacing: 8) {
                Text("НОМЕР ТЕЛЕФОНА")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    // Country Flag Badge
                    Text(PhoneFormatter.flagForNumber(phoneNumber))
                        .font(.system(size: 22))
                    
                    // Main Phone TextField with Auto-formatting
                    TextField("+7 925 043 1339", text: $phoneNumber)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { newValue in
                            let formatted = PhoneFormatter.format(newValue)
                            if formatted != phoneNumber {
                                phoneNumber = formatted
                            }
                        }
                    
                    // Clear Button
                    if !phoneNumber.isEmpty && phoneNumber != "+7 " {
                        Button(action: {
                            phoneNumber = "+7 "
                            SoundHapticManager.shared.playLightImpact()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1.2)
                )
                
                Text("Официальный проверочный код придет в приложение Telegram")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            // Send Code Button
            Button(action: {
                Task {
                    let cleanPhone = PhoneFormatter.cleanDigits(phoneNumber)
                    let success = await client.sendCode(phoneNumber: cleanPhone, dc: selectedDc)
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
            
            // OTP Code Input Field
            TextField("12345", text: $otpCode)
                .font(.system(size: 34, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding(16)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                )
            
            Text("Введите 5 цифр из служебного сообщения от Telegram")
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
                        Image(systemName: "lock.open.fill")
                        Text("Войти в Telegram")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.85), Color(red: 0.1, green: 0.7, blue: 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.green.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .disabled(client.isLoading || otpCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    // MARK: - 2FA Password Step
    private var passwordStepView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.yellow)
                Text("Двухфакторная аутентификация")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Введите облачный пароль от вашего аккаунта Telegram")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            SecureField("Ваш пароль 2FA", text: $password2FA)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1.2)
                )
            
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
                        Text("Подтвердить пароль")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.yellow.opacity(0.85))
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.yellow.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(client.isLoading || password2FA.isEmpty)
        }
    }
}
