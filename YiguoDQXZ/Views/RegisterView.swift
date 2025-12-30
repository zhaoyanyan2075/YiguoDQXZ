//
//  RegisterView.swift
//  YiguoDQXZ
//
//  Created by 赵燕燕 on 2025/12/27.
//

import SwiftUI
import Combine

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var email = ""
    @State private var showLogin = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 标题区域
                    headerSection

                    // 输入表单
                    formSection

                    // 注册按钮
                    registerButton

                    // 切换登录
                    loginToggle
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authManager)
        }
        .alert(isSuccess ? "注册成功" : "注册失败", isPresented: $showAlert) {
            Button("确定") {
                if isSuccess {
                    // 注册成功后可以自动登录或跳转
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary)

            Text("幸存者注册")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("加入幸存者联盟，开启你的末日生存之旅")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }

    // MARK: - 输入表单
    private var formSection: some View {
        VStack(spacing: 16) {
            // 用户名输入
            InputField(
                icon: "person.fill",
                placeholder: "幸存者ID（用户名）",
                text: $username
            )

            // 邮箱输入
            InputField(
                icon: "envelope.fill",
                placeholder: "邮箱地址",
                text: $email,
                keyboardType: .emailAddress
            )

            // 密码输入
            InputField(
                icon: "lock.fill",
                placeholder: "设置密码（至少6位）",
                text: $password,
                isSecure: true
            )

            // 确认密码
            InputField(
                icon: "lock.shield.fill",
                placeholder: "确认密码",
                text: $confirmPassword,
                isSecure: true
            )
        }
    }

    // MARK: - 注册按钮
    private var registerButton: some View {
        Button(action: performRegister) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.badge.plus")
                    Text("加入幸存者")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canRegister ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canRegister || authManager.isLoading)
        .padding(.top, 8)
    }

    // MARK: - 切换登录
    private var loginToggle: some View {
        HStack {
            Text("已有账号？")
                .foregroundColor(ApocalypseTheme.textSecondary)
            Button("去登录") {
                showLogin = true
            }
            .foregroundColor(ApocalypseTheme.primary)
            .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    // MARK: - 验证逻辑
    private var canRegister: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }

    // MARK: - 执行注册
    private func performRegister() {
        // 验证密码匹配
        guard password == confirmPassword else {
            alertMessage = "两次输入的密码不一致"
            isSuccess = false
            showAlert = true
            return
        }

        // 使用 OTP 流程发送验证码
        Task {
            await authManager.sendRegisterOTP(email: email)

            if authManager.otpSent {
                alertMessage = "验证码已发送到 \(email)，请查收邮件完成注册"
                isSuccess = true
                showAlert = true
            } else if let error = authManager.errorMessage {
                alertMessage = error
                isSuccess = false
                showAlert = true
            }
        }
    }
}

// MARK: - 自定义输入框组件
struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(ApocalypseTheme.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager.shared)
}
