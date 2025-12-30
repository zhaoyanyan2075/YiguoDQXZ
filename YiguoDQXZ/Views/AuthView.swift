//
//  AuthView.swift
//  YiguoDQXZ (EarthLord)
//
//  认证页面 - 登录/注册/忘记密码
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI

// MARK: - 认证页面主视图
struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared

    /// 当前选中的Tab：0=登录，1=注册
    @State private var selectedTab = 0

    /// 是否显示忘记密码弹窗
    @State private var showForgotPassword = false

    /// Toast 提示
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.10, blue: 0.18),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo 和标题
                    headerSection

                    // Tab 切换
                    tabSelector

                    // 内容区域
                    if selectedTab == 0 {
                        LoginSection(
                            authManager: authManager,
                            showForgotPassword: $showForgotPassword
                        )
                    } else {
                        RegisterSection(authManager: authManager)
                    }

                    // 分隔线
                    dividerSection

                    // 第三方登录
                    socialLoginSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }

            // 加载遮罩
            if authManager.isLoading {
                loadingOverlay
            }

            // Toast 提示
            if showToast {
                toastView
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(authManager: authManager)
        }
        .onChange(of: authManager.errorMessage) { _, newValue in
            if let message = newValue {
                showToastMessage(message)
            }
        }
    }

    // MARK: - Logo 和标题
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary,
                                ApocalypseTheme.primary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: ApocalypseTheme.primary.opacity(0.5), radius: 15)

                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            // 标题
            VStack(spacing: 4) {
                Text("地球新主")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text("EARTH LORD")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .tracking(3)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Tab 切换
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "登录", isSelected: selectedTab == 0) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                    authManager.resetFlowState()
                }
            }

            TabButton(title: "注册", isSelected: selectedTab == 1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                    authManager.resetFlowState()
                }
            }
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 分隔线
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(ApocalypseTheme.textSecondary.opacity(0.3))
                .frame(height: 1)

            Text("或者使用以下方式登录")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .fixedSize()

            Rectangle()
                .fill(ApocalypseTheme.textSecondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.top, 16)
    }

    // MARK: - 第三方登录
    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            // Apple 登录
            Button(action: {
                showToastMessage("Apple 登录即将开放")
            }) {
                HStack {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                    Text("使用 Apple 登录")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Google 登录
            Button(action: {
                showToastMessage("Google 登录即将开放")
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("使用 Google 登录")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 加载遮罩
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("请稍候...")
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Toast 视图
    private var toastView: some View {
        VStack {
            Spacer()

            Text(toastMessage)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: showToast)
    }

    // MARK: - 显示 Toast
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        authManager.clearError()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showToast = false
        }
    }
}

// MARK: - Tab 按钮
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isSelected ? ApocalypseTheme.primary.opacity(0.15) : Color.clear
                )
        }
    }
}

// MARK: - ==================== 登录区域 ====================
struct LoginSection: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showForgotPassword: Bool

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            // 邮箱输入
            AuthTextField(
                icon: "envelope.fill",
                placeholder: "邮箱地址",
                text: $email,
                keyboardType: .emailAddress
            )

            // 密码输入
            AuthTextField(
                icon: "lock.fill",
                placeholder: "密码",
                text: $password,
                isSecure: true
            )

            // 登录按钮
            Button(action: performLogin) {
                Text("登录")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canLogin ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canLogin || authManager.isLoading)

            // 忘记密码
            Button(action: { showForgotPassword = true }) {
                Text("忘记密码？")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.primary)
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }

    private func performLogin() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

// MARK: - ==================== 注册区域 ====================
struct RegisterSection: View {
    @ObservedObject var authManager: AuthManager

    @State private var email = ""
    @State private var otpCode = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    /// 重发倒计时
    @State private var resendCountdown = 0
    @State private var countdownTimer: Timer?

    /// 当前步骤：根据 authManager 状态自动判断
    private var currentStep: Int {
        if authManager.otpVerified && authManager.needsPasswordSetup {
            return 3  // 已验证OTP，需要设置密码
        } else if authManager.otpSent {
            return 2  // 已发送OTP，等待验证
        } else {
            return 1  // 初始状态，输入邮箱
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 步骤指示器
            StepIndicator(currentStep: currentStep, totalSteps: 3)
                .padding(.bottom, 8)

            // 根据步骤显示不同内容
            switch currentStep {
            case 1:
                step1EmailInput
            case 2:
                step2OTPVerification
            case 3:
                step3PasswordSetup
            default:
                EmptyView()
            }
        }
        .padding(.top, 8)
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }

    // MARK: - 第一步：邮箱输入
    private var step1EmailInput: some View {
        VStack(spacing: 16) {
            Text("输入你的邮箱开始注册")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            AuthTextField(
                icon: "envelope.fill",
                placeholder: "邮箱地址",
                text: $email,
                keyboardType: .emailAddress
            )

            Button(action: sendOTP) {
                Text("发送验证码")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(!email.isEmpty ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(email.isEmpty || authManager.isLoading)
        }
    }

    // MARK: - 第二步：验证码验证
    private var step2OTPVerification: some View {
        VStack(spacing: 16) {
            Text("验证码已发送至")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text(email)
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.primary)

            // 6位验证码输入
            OTPInputField(code: $otpCode)

            // 验证按钮
            Button(action: verifyOTP) {
                Text("验证")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(otpCode.count == 6 ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(otpCode.count != 6 || authManager.isLoading)

            // 重发验证码
            HStack {
                if resendCountdown > 0 {
                    Text("\(resendCountdown)秒后可重新发送")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                } else {
                    Button("重新发送验证码") {
                        resendOTP()
                    }
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - 第三步：设置密码
    private var step3PasswordSetup: some View {
        VStack(spacing: 16) {
            Text("设置你的登录密码")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            AuthTextField(
                icon: "lock.fill",
                placeholder: "设置密码（至少6位）",
                text: $password,
                isSecure: true
            )

            AuthTextField(
                icon: "lock.shield.fill",
                placeholder: "确认密码",
                text: $confirmPassword,
                isSecure: true
            )

            // 密码不匹配提示
            if !confirmPassword.isEmpty && password != confirmPassword {
                Text("两次输入的密码不一致")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
            }

            Button(action: completeRegistration) {
                Text("完成注册")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canComplete ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canComplete || authManager.isLoading)
        }
    }

    private var canComplete: Bool {
        password.count >= 6 && password == confirmPassword
    }

    // MARK: - 操作方法
    private func sendOTP() {
        Task {
            await authManager.sendRegisterOTP(email: email)
            if authManager.otpSent {
                startCountdown()
            }
        }
    }

    private func resendOTP() {
        Task {
            await authManager.sendRegisterOTP(email: email)
            if authManager.otpSent {
                startCountdown()
            }
        }
    }

    private func verifyOTP() {
        Task {
            await authManager.verifyRegisterOTP(email: email, code: otpCode)
        }
    }

    private func completeRegistration() {
        Task {
            await authManager.completeRegistration(password: password)
        }
    }

    private func startCountdown() {
        resendCountdown = 60
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                countdownTimer?.invalidate()
            }
        }
    }
}

// MARK: - ==================== 忘记密码弹窗 ====================
struct ForgotPasswordSheet: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var resendCountdown = 0
    @State private var countdownTimer: Timer?

    /// 当前步骤
    private var currentStep: Int {
        if authManager.otpVerified && authManager.needsPasswordSetup {
            return 3
        } else if authManager.otpSent {
            return 2
        } else {
            return 1
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // 图标
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(ApocalypseTheme.primary)
                        .padding(.top, 20)

                    Text("重置密码")
                        .font(.title2.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    // 步骤指示器
                    StepIndicator(currentStep: currentStep, totalSteps: 3)

                    // 内容
                    switch currentStep {
                    case 1:
                        forgotStep1
                    case 2:
                        forgotStep2
                    case 3:
                        forgotStep3
                    default:
                        EmptyView()
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)

                // 加载遮罩
                if authManager.isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        authManager.resetFlowState()
                        dismiss()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }

    // MARK: - 第一步：输入邮箱
    private var forgotStep1: some View {
        VStack(spacing: 16) {
            Text("输入你注册时使用的邮箱")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            AuthTextField(
                icon: "envelope.fill",
                placeholder: "邮箱地址",
                text: $email,
                keyboardType: .emailAddress
            )

            Button(action: sendResetOTP) {
                Text("发送验证码")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(!email.isEmpty ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(email.isEmpty || authManager.isLoading)

            // 错误提示
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
            }
        }
    }

    // MARK: - 第二步：验证码
    private var forgotStep2: some View {
        VStack(spacing: 16) {
            Text("验证码已发送至")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text(email)
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.primary)

            OTPInputField(code: $otpCode)

            Button(action: verifyResetOTP) {
                Text("验证")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(otpCode.count == 6 ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(otpCode.count != 6 || authManager.isLoading)

            // 重发
            HStack {
                if resendCountdown > 0 {
                    Text("\(resendCountdown)秒后可重新发送")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                } else {
                    Button("重新发送验证码") {
                        resendResetOTP()
                    }
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }

            // 错误提示
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
            }
        }
    }

    // MARK: - 第三步：设置新密码
    private var forgotStep3: some View {
        VStack(spacing: 16) {
            Text("设置你的新密码")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            AuthTextField(
                icon: "lock.fill",
                placeholder: "新密码（至少6位）",
                text: $newPassword,
                isSecure: true
            )

            AuthTextField(
                icon: "lock.shield.fill",
                placeholder: "确认新密码",
                text: $confirmPassword,
                isSecure: true
            )

            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("两次输入的密码不一致")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
            }

            Button(action: resetPassword) {
                Text("重置密码")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canReset ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canReset || authManager.isLoading)

            // 错误提示
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
            }
        }
    }

    private var canReset: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    // MARK: - 操作方法
    private func sendResetOTP() {
        Task {
            await authManager.sendResetOTP(email: email)
            if authManager.otpSent {
                startCountdown()
            }
        }
    }

    private func resendResetOTP() {
        Task {
            await authManager.sendResetOTP(email: email)
            if authManager.otpSent {
                startCountdown()
            }
        }
    }

    private func verifyResetOTP() {
        Task {
            await authManager.verifyResetOTP(email: email, code: otpCode)
        }
    }

    private func resetPassword() {
        Task {
            await authManager.resetPassword(newPassword: newPassword)
            if authManager.isAuthenticated {
                dismiss()
            }
        }
    }

    private func startCountdown() {
        resendCountdown = 60
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                countdownTimer?.invalidate()
            }
        }
    }
}

// MARK: - ==================== 通用组件 ====================

// MARK: - 步骤指示器
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary.opacity(0.3))
                    .frame(width: 10, height: 10)

                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary.opacity(0.3))
                        .frame(width: 30, height: 2)
                }
            }
        }
    }
}

// MARK: - 输入框组件
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .foregroundColor(ApocalypseTheme.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if isSecure {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - OTP 输入框
struct OTPInputField: View {
    @Binding var code: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                OTPDigitBox(
                    digit: getDigit(at: index),
                    isFocused: code.count == index
                )
            }
        }
        .overlay(
            // 隐藏的 TextField 用于输入
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .foregroundColor(.clear)
                .accentColor(.clear)
                .onChange(of: code) { _, newValue in
                    // 限制6位数字
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count <= 6 {
                        code = filtered
                    } else {
                        code = String(filtered.prefix(6))
                    }
                }
        )
    }

    private func getDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

// MARK: - OTP 单个数字框
struct OTPDigitBox: View {
    let digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(ApocalypseTheme.cardBackground)
                .frame(width: 45, height: 55)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isFocused ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary.opacity(0.3),
                            lineWidth: isFocused ? 2 : 1
                        )
                )

            Text(digit)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)
        }
    }
}

// MARK: - 预览
#Preview {
    AuthView()
}
