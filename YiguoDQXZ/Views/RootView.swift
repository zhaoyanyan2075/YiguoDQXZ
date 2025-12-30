//
//  RootView.swift
//  YiguoDQXZ
//
//  Created by 赵燕燕 on 2025/12/25.
//

import SwiftUI
import Combine

/// 根视图：控制启动页、认证流程与主界面的切换
struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 显示启动页
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else {
                // 根据认证状态显示不同界面
                switch authManager.authState {
                case .unknown:
                    // 正在检查登录状态
                    loadingView
                        .transition(.opacity)
                case .signedOut:
                    // 未登录，显示认证界面
                    AuthContainerView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                case .signedIn:
                    // 已登录，显示主界面
                    MainTabView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.authState == .signedIn)
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                    .scaleEffect(1.2)

                Text("正在检查登录状态...")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
    }
}

// MARK: - 认证容器视图
struct AuthContainerView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showRegister = false

    var body: some View {
        NavigationView {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                if showRegister {
                    RegisterView()
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showRegister ? "登录" : "注册") {
                        withAnimation {
                            showRegister.toggle()
                        }
                    }
                    .foregroundColor(ApocalypseTheme.accent)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
