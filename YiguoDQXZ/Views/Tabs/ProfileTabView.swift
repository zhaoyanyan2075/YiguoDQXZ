//
//  ProfileTabView.swift
//  YiguoDQXZ
//
//  个人页面 - 显示用户信息和登出功能
//
//  Created by 赵燕燕 on 2025/12/25.
//

import SwiftUI
import Supabase

struct ProfileTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 头像区域
                        avatarSection

                        // 用户信息卡片
                        userInfoCard

                        // 统计数据
                        statsSection

                        // 登出按钮
                        logoutButton
                    }
                    .padding()
                }

                // 加载遮罩
                if authManager.isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("正在退出...")
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(16)
                }
            }
            .navigationTitle("幸存者档案")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("确认登出", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("登出", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("确定要退出当前账号吗？")
        }
    }

    // MARK: - 头像区域
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.cardBackground)
                    .frame(width: 100, height: 100)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            Text(username)
                .font(.title2.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(userEmail)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(.top, 20)
    }

    // MARK: - 用户信息卡片
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            InfoRow(icon: "person.fill", title: "用户名", value: username)
            Divider().background(ApocalypseTheme.textSecondary.opacity(0.3))
            InfoRow(icon: "envelope.fill", title: "邮箱", value: userEmail)
            Divider().background(ApocalypseTheme.textSecondary.opacity(0.3))
            InfoRow(icon: "calendar", title: "加入时间", value: joinDate)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 统计数据
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(icon: "map.fill", title: "领地", value: "0")
            StatCard(icon: "mappin.circle.fill", title: "兴趣点", value: "0")
            StatCard(icon: "star.fill", title: "成就", value: "0")
        }
    }

    // MARK: - 登出按钮
    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("退出登录")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ApocalypseTheme.danger.opacity(0.2))
            .foregroundColor(ApocalypseTheme.danger)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ApocalypseTheme.danger, lineWidth: 1)
            )
        }
        .padding(.top, 20)
    }

    // MARK: - 计算属性
    private var username: String {
        if let user = authManager.currentUser,
           let metadata = user.userMetadata["username"] {
            // 尝试从 AnyJSON 获取字符串值
            if case .string(let value) = metadata {
                return value
            }
        }
        return "幸存者"
    }

    private var userEmail: String {
        authManager.currentUser?.email ?? "未知"
    }

    private var joinDate: String {
        guard let user = authManager.currentUser else { return "未知" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: user.createdAt)
    }

    // MARK: - 登出操作
    private func performLogout() {
        Task {
            await authManager.signOut()
        }
    }
}

// MARK: - 信息行组件
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.primary)
                .frame(width: 24)

            Text(title)
                .foregroundColor(ApocalypseTheme.textSecondary)

            Spacer()

            Text(value)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 统计卡片组件
struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ApocalypseTheme.primary)

            Text(value)
                .font(.title.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager.shared)
}
