//
//  RootView.swift
//  YiguoDQXZ
//
//  根视图：控制启动页、认证流程与主界面的切换
//
//  Created by 赵燕燕 on 2025/12/25.
//

import SwiftUI

/// 根视图：控制启动页、认证流程与主界面的切换
struct RootView: View {
    /// 认证管理器（单例）
    @StateObject private var authManager = AuthManager.shared

    /// 启动页是否完成
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 显示启动页
                SplashView(authManager: authManager, isFinished: $splashFinished)
                    .transition(.opacity)
            } else {
                // 根据认证状态显示不同界面
                if authManager.isAuthenticated {
                    // 已登录且完成所有流程 → 显示主界面
                    MainTabView()
                        .environmentObject(authManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    // 未登录或注册流程中 → 显示认证页面
                    // 使用 id 确保 SwiftUI 不会重建视图
                    AuthView()
                        .id("authView")
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: splashFinished)
        .animation(.easeInOut(duration: 0.4), value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
}
