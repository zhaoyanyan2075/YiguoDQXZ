//
//  LoginView.swift
//  YiguoDQXZ
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showForgotPassword = false
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

                    // 登录按钮
                    loginButton

                    // 忘记密码
                    forgotPasswordButton

                    // 分隔线
                    divider

                    // 注册提示
                    registerToggle
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authManager)
        }
        .alert(isSuccess ? "登录成功" : "登录失败", isPresented: $showAlert) {
            Button("确定") {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary)

            Text("幸存者登录")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("欢迎回来，继续你的末日生存之旅")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }

    // MARK: - 输入表单
    private var formSection: some View {
        VStack(spacing: 16) {
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
                placeholder: "密码",
                text: $password,
                isSecure: true
            )
        }
    }

    // MARK: - 登录按钮
    private var loginButton: some View {
        Button(action: performLogin) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("登录")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canLogin ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canLogin || authManager.isLoading)
        .padding(.top, 8)
    }

    // MARK: - 忘记密码
    private var forgotPasswordButton: some View {
        Button("忘记密码？") {
            showForgotPassword = true
        }
        .font(.subheadline)
        .foregroundColor(ApocalypseTheme.primary)
    }

    // MARK: - 分隔线
    private var divider: some View {
        HStack {
            Rectangle()
                .fill(ApocalypseTheme.textSecondary.opacity(0.3))
                .frame(height: 1)
            Text("或")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Rectangle()
                .fill(ApocalypseTheme.textSecondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    // MARK: - 注册提示
    private var registerToggle: some View {
        HStack {
            Text("还没有账号？")
                .foregroundColor(ApocalypseTheme.textSecondary)
            Button("立即注册") {
                showRegister = true
            }
            .foregroundColor(ApocalypseTheme.primary)
            .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    // MARK: - 验证逻辑
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty
    }

    // MARK: - 执行登录
    private func performLogin() {
        Task {
            await authManager.signIn(email: email, password: password)

            if authManager.isAuthenticated {
                alertMessage = "欢迎回来！"
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

// MARK: - 忘记密码视图
struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(ApocalypseTheme.primary)

                    Text("重置密码")
                        .font(.title2.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("输入你注册时使用的邮箱，我们会发送重置链接给你")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    InputField(
                        icon: "envelope.fill",
                        placeholder: "邮箱地址",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, 24)

                    Button(action: sendResetEmail) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("发送重置链接")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(!email.isEmpty ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || authManager.isLoading)
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
        .alert(isSuccess ? "发送成功" : "发送失败", isPresented: $showAlert) {
            Button("确定") {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func sendResetEmail() {
        Task {
            await authManager.sendResetOTP(email: email)

            if authManager.otpSent {
                alertMessage = "重置验证码已发送到 \(email)，请查收邮件"
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

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
