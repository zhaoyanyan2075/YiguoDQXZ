//
//  AuthManager.swift
//  YiguoDQXZ
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI
import Combine
import Supabase
import Auth

// MARK: - Supabase 客户端单例
// 注意：请将此 API Key 替换为你的 Supabase 项目的 anon (public) key
// 可以在 Supabase Dashboard -> Settings -> API 中找到
let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: "https://dpuvnvghlbalwdivxzpc.supabase.co")!,
    supabaseKey: "sb_publishable_Z2zlgDg0cMPGQlSe3cxXiA_SSMizAdb"
)

// MARK: - 认证状态枚举
enum AuthState {
    case unknown      // 初始状态，正在检查
    case signedOut    // 未登录
    case signedIn     // 已登录
}

// MARK: - 认证错误类型
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailInUse
    case invalidCredentials
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "邮箱格式不正确"
        case .weakPassword:
            return "密码太弱，至少需要6个字符"
        case .emailInUse:
            return "该邮箱已被注册"
        case .invalidCredentials:
            return "邮箱或密码错误"
        case .networkError:
            return "网络连接失败，请检查网络"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - 认证管理器
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var authState: AuthState = .unknown
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {
        Task {
            await checkCurrentSession()
        }
    }

    // MARK: - 检查当前会话
    func checkCurrentSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabaseClient.auth.session
            currentUser = session.user
            authState = .signedIn
        } catch {
            currentUser = nil
            authState = .signedOut
        }
    }

    // MARK: - 注册
    func signUp(email: String, password: String, username: String) async throws {
        // 验证输入
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["username": .string(username)]
            )

            currentUser = response.user
            authState = .signedIn
        } catch {
            let errorString = String(describing: error)
            if errorString.contains("already registered") || errorString.contains("duplicate") {
                throw AuthError.emailInUse
            } else if errorString.contains("network") || errorString.contains("NSURLError") {
                throw AuthError.networkError
            } else {
                throw AuthError.unknown(error.localizedDescription)
            }
        }
    }

    // MARK: - 登录
    func signIn(email: String, password: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )

            currentUser = session.user
            authState = .signedIn
        } catch {
            let errorString = String(describing: error)
            if errorString.contains("Invalid login") || errorString.contains("invalid_credentials") {
                throw AuthError.invalidCredentials
            } else if errorString.contains("network") || errorString.contains("NSURLError") {
                throw AuthError.networkError
            } else {
                throw AuthError.unknown(error.localizedDescription)
            }
        }
    }

    // MARK: - 登出
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabaseClient.auth.signOut()
            currentUser = nil
            authState = .signedOut
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - 重置密码
    func resetPassword(email: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await supabaseClient.auth.resetPasswordForEmail(email)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - 邮箱验证
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
