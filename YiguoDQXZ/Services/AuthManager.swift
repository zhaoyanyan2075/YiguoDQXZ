//
//  AuthManager.swift
//  YiguoDQXZ (EarthLord)
//
//  认证管理器 - 处理用户注册、登录、找回密码等认证流程
//
//  认证流程说明：
//  - 注册：发验证码 → 验证OTP（此时已登录但无密码）→ 强制设置密码 → 完成
//  - 登录：邮箱 + 密码（直接登录）
//  - 找回密码：发验证码 → 验证OTP（此时已登录）→ 设置新密码 → 完成
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI
import Supabase
import Combine

// MARK: - 认证管理器
@MainActor
class AuthManager: ObservableObject {

    // MARK: - 单例
    static let shared = AuthManager()

    // MARK: - 发布属性

    /// 是否已完成认证（已登录且完成所有流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP验证后需要设置密码才能进入主页）
    @Published var needsPasswordSetup: Bool = false

    /// 当前登录用户
    @Published var currentUser: User?

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String?

    /// 验证码是否已发送
    @Published var otpSent: Bool = false

    /// 验证码是否已验证（等待设置密码）
    @Published var otpVerified: Bool = false

    /// 是否正在注册流程中（防止自动认证）
    @Published var isInRegistrationFlow: Bool = false

    /// 是否已完成初始化检查
    @Published var isInitialized: Bool = false

    // MARK: - 私有属性

    /// 认证状态监听任务
    private var authStateTask: Task<Void, Never>?

    // MARK: - 初始化
    private init() {
        // 启动认证状态监听
        startAuthStateListener()
    }

    deinit {
        // 取消监听任务
        authStateTask?.cancel()
    }

    // MARK: - ==================== 认证状态监听 ====================

    /// 启动认证状态变化监听
    /// - Note: 监听 Supabase auth 状态变化，自动更新 UI
    private func startAuthStateListener() {
        authStateTask = Task { [weak self] in
            // 监听认证状态变化
            for await (event, session) in supabase.auth.authStateChanges {
                guard let self = self else { break }

                await MainActor.run {
                    self.handleAuthStateChange(event: event, session: session)
                }
            }
        }
    }

    /// 处理认证状态变化
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        print("🔔 认证状态变化: \(event)")

        switch event {
        case .initialSession:
            // 初始会话检查完成
            if let session = session {
                // 检查会话是否过期
                if isSessionExpired(session) {
                    handleSessionExpired()
                } else {
                    currentUser = session.user
                    checkUserPasswordStatus(user: session.user)
                    print("✅ 初始会话: \(session.user.email ?? "未知")")
                }
            } else {
                currentUser = nil
                isAuthenticated = false
                print("ℹ️ 无初始会话")
            }
            isInitialized = true

        case .signedIn:
            // 用户登录
            if let session = session {
                currentUser = session.user
                // 如果正在注册流程中，不要自动设置认证状态
                // 必须等用户完成设置用户名和密码
                if isInRegistrationFlow {
                    print("✅ 用户登录（注册流程中，不自动认证）: \(session.user.email ?? "未知")")
                } else if !otpSent && !otpVerified {
                    checkUserPasswordStatus(user: session.user)
                    print("✅ 用户登录: \(session.user.email ?? "未知")")
                } else {
                    print("✅ 用户登录（OTP流程中）: \(session.user.email ?? "未知")")
                }
            }

        case .signedOut:
            // 用户登出或会话过期
            clearAllState()
            print("👋 用户登出")

        case .tokenRefreshed:
            // Token 刷新成功
            if let session = session {
                currentUser = session.user
                print("🔄 Token 已刷新")
            }

        case .userUpdated:
            // 用户信息更新
            if let session = session {
                currentUser = session.user
                print("📝 用户信息已更新")
            }

        case .passwordRecovery:
            // 密码恢复流程
            print("🔑 密码恢复流程")
            needsPasswordSetup = true

        case .mfaChallengeVerified:
            // MFA 验证完成
            print("🔐 MFA 验证完成")

        case .userDeleted:
            // 用户删除
            clearAllState()
            print("🗑️ 用户已删除")
        }
    }

    /// 检查会话是否过期
    private func isSessionExpired(_ session: Session) -> Bool {
        // expiresAt 是 TimeInterval (秒数)，需要与当前时间的时间戳比较
        return session.expiresAt < Date().timeIntervalSince1970
    }

    /// 处理会话过期
    private func handleSessionExpired() {
        print("⏰ 会话已过期，需要重新登录")
        clearAllState()
        errorMessage = "登录已过期，请重新登录"
    }

    /// 清除所有本地状态
    private func clearAllState() {
        currentUser = nil
        isAuthenticated = false
        needsPasswordSetup = false
        otpSent = false
        otpVerified = false
        isInRegistrationFlow = false
        errorMessage = nil
    }

    /// 检查用户密码状态
    private func checkUserPasswordStatus(user: User) {
        // 检查用户是否有 email identity（说明设置了密码）
        if let identities = user.identities,
           identities.contains(where: { $0.provider == "email" }) {
            isAuthenticated = true
            needsPasswordSetup = false
        } else {
            // 没有 email identity，可能需要设置密码
            isAuthenticated = false
            needsPasswordSetup = true
        }
    }

    // MARK: - ==================== 注册流程 ====================

    /// 发送注册验证码
    /// - Parameter email: 用户邮箱
    /// - Note: 调用 signInWithOTP 并设置 shouldCreateUser: true
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        isInRegistrationFlow = true  // 标记进入注册流程

        do {
            // 发送 OTP 验证码，允许创建新用户
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            otpSent = true
            print("📧 注册验证码已发送到: \(email)")

        } catch {
            errorMessage = parseError(error)
            print("❌ 发送注册验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 验证注册 OTP 验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 6位验证码
    /// - Note: 验证成功后用户已登录，但 isAuthenticated 保持 false，必须设置密码
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP（type: .email 用于注册/登录）
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true  // 标记需要设置密码
            isAuthenticated = false    // 强制保持未认证状态，必须完成设置密码
            // isInRegistrationFlow 保持 true，直到 completeRegistration 完成

            print("✅ 注册验证码验证成功，等待设置用户名和密码")

        } catch {
            errorMessage = parseError(error)
            isInRegistrationFlow = false  // 验证失败，退出注册流程
            print("❌ 验证注册验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 完成注册（设置用户名和密码）
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 用户设置的密码
    /// - Note: 必须在 verifyRegisterOTP 成功后调用
    func completeRegistration(username: String, password: String) async {
        guard otpVerified else {
            errorMessage = "请先验证邮箱验证码"
            return
        }

        guard let userId = currentUser?.id else {
            errorMessage = "用户信息异常，请重试"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 1. 更新用户密码
            try await supabase.auth.update(user: UserAttributes(password: password))

            // 2. 创建用户 profile（保存用户名）
            try await supabase
                .from("profiles")
                .insert([
                    "id": userId.uuidString,
                    "username": username
                ])
                .execute()

            // 设置密码成功，完成注册流程
            needsPasswordSetup = false
            otpSent = false
            otpVerified = false
            isInRegistrationFlow = false  // 退出注册流程
            isAuthenticated = true        // 最后才设置认证成功

            print("🎉 注册完成！用户名: \(username)")

        } catch {
            // 检查是否是用户名重复错误
            let errorString = String(describing: error)
            if errorString.contains("duplicate") || errorString.contains("unique") {
                errorMessage = "该用户名已被使用，请换一个"
            } else {
                errorMessage = parseError(error)
            }
            print("❌ 完成注册失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - ==================== 登录流程 ====================

    /// 邮箱密码登录
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            currentUser = session.user
            isAuthenticated = true

            print("✅ 登录成功: \(email)")

        } catch {
            errorMessage = parseError(error)
            print("❌ 登录失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - ==================== 找回密码流程 ====================

    /// 发送密码重置验证码
    /// - Parameter email: 用户邮箱
    /// - Note: 会触发 Supabase 的 Reset Password 邮件模板
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 发送密码重置邮件
            try await supabase.auth.resetPasswordForEmail(email)

            otpSent = true
            print("📧 密码重置验证码已发送到: \(email)")

        } catch {
            errorMessage = parseError(error)
            print("❌ 发送重置验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 验证密码重置 OTP 验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 6位验证码
    /// - Note: type 是 .recovery 不是 .email
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP（type: .recovery 用于密码重置）
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .recovery  // ⚠️ 重要：密码重置使用 .recovery 类型
            )

            // 验证成功，用户已登录
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true  // 标记需要设置新密码

            print("✅ 重置验证码验证成功，等待设置新密码")

        } catch {
            errorMessage = parseError(error)
            print("❌ 验证重置验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 重置密码（设置新密码）
    /// - Parameter newPassword: 新密码
    /// - Note: 必须在 verifyResetOTP 成功后调用
    func resetPassword(newPassword: String) async {
        guard otpVerified else {
            errorMessage = "请先验证邮箱验证码"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            try await supabase.auth.update(user: UserAttributes(password: newPassword))

            // 设置密码成功，完成重置流程
            needsPasswordSetup = false
            isAuthenticated = true
            otpSent = false
            otpVerified = false

            print("🎉 密码重置成功！")

        } catch {
            errorMessage = parseError(error)
            print("❌ 重置密码失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - ==================== 第三方登录（预留） ====================

    /// Apple 登录
    /// - TODO: 实现 Apple Sign In
    func signInWithApple() async {
        // TODO: 实现 Apple 登录
        // 1. 使用 AuthenticationServices 获取 Apple 凭证
        // 2. 调用 supabase.auth.signInWithIdToken(credentials:)
        print("⚠️ Apple 登录功能待实现")
        errorMessage = "Apple 登录功能即将推出"
    }

    /// Google 登录
    /// - TODO: 实现 Google Sign In
    func signInWithGoogle() async {
        // TODO: 实现 Google 登录
        // 1. 使用 GoogleSignIn SDK 获取 ID Token
        // 2. 调用 supabase.auth.signInWithIdToken(credentials:)
        print("⚠️ Google 登录功能待实现")
        errorMessage = "Google 登录功能即将推出"
    }

    // MARK: - ==================== 其他方法 ====================

    /// 登出
    /// - Note: 调用 Supabase signOut 并清除所有本地状态
    func signOut() async {
        isLoading = true

        do {
            // 调用 Supabase 登出
            try await supabase.auth.signOut()

            // 立即清除本地状态（不等待 authStateChanges 回调）
            clearAllState()

            print("👋 已登出")

        } catch {
            // 即使服务器登出失败，也清除本地状态
            clearAllState()
            print("⚠️ 服务器登出失败，但已清除本地状态: \(error)")
        }

        isLoading = false
    }

    /// 检查现有会话
    /// - Note: 启动时调用，恢复登录状态
    func checkSession() async {
        isLoading = true

        do {
            let session = try await supabase.auth.session
            currentUser = session.user

            // 检查用户密码状态
            checkUserPasswordStatus(user: session.user)

            print("✅ 会话恢复成功: \(session.user.email ?? "未知邮箱")")

        } catch {
            // 没有有效会话，用户未登录
            currentUser = nil
            isAuthenticated = false
            print("ℹ️ 无有效会话，需要登录")
        }

        isLoading = false
        isInitialized = true
    }

    /// 重置流程状态（用于返回上一步或取消流程）
    func resetFlowState() {
        otpSent = false
        otpVerified = false
        needsPasswordSetup = false
        isInRegistrationFlow = false
        errorMessage = nil
    }

    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }

    // MARK: - ==================== 私有方法 ====================

    /// 解析错误信息，返回用户友好的提示
    private func parseError(_ error: Error) -> String {
        let errorString = String(describing: error)

        // 网络错误
        if errorString.contains("NSURLError") ||
           errorString.contains("network") ||
           errorString.contains("Internet") {
            return "网络连接失败，请检查网络"
        }

        // 邮箱相关错误
        if errorString.contains("invalid_email") ||
           errorString.contains("Invalid email") {
            return "邮箱格式不正确"
        }

        if errorString.contains("email_not_confirmed") {
            return "邮箱未验证"
        }

        if errorString.contains("user_already_exists") ||
           errorString.contains("already registered") {
            return "该邮箱已被注册"
        }

        // 密码相关错误
        if errorString.contains("weak_password") {
            return "密码强度不够，请设置更复杂的密码"
        }

        if errorString.contains("invalid_credentials") ||
           errorString.contains("Invalid login") {
            return "邮箱或密码错误"
        }

        // OTP 相关错误
        if errorString.contains("otp_expired") ||
           errorString.contains("Token has expired") {
            return "验证码已过期，请重新获取"
        }

        if errorString.contains("otp_disabled") {
            return "验证码功能未启用"
        }

        if errorString.contains("invalid") && errorString.contains("otp") {
            return "验证码错误，请重新输入"
        }

        // 频率限制
        if errorString.contains("rate_limit") ||
           errorString.contains("too_many_requests") {
            return "请求过于频繁，请稍后再试"
        }

        // 用户不存在
        if errorString.contains("user_not_found") {
            return "用户不存在"
        }

        // 默认错误
        return "操作失败，请稍后重试"
    }
}
