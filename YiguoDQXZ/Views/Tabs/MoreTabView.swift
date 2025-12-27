//
//  MoreTabView.swift
//  YiguoDQXZ
//
//  Created by 赵燕燕 on 2025/12/25.
//

import SwiftUI

struct MoreTabView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 开发测试区域
                        sectionHeader("开发测试")

                        // Supabase 连接测试
                        NavigationLink(destination: SupabaseTestView()) {
                            menuRow(
                                icon: "server.rack",
                                title: "Supabase 连接测试",
                                subtitle: "检测后端服务连接状态"
                            )
                        }

                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(ApocalypseTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - 区域标题
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - 菜单行
    private func menuRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ApocalypseTheme.primary)
                .frame(width: 40, height: 40)
                .background(ApocalypseTheme.primary.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    MoreTabView()
}
