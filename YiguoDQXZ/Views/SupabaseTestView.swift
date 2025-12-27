//
//  SupabaseTestView.swift
//  YiguoDQXZ
//
//  Created by 赵燕燕 on 2025/12/25.
//

import SwiftUI
import Supabase

// MARK: - Supabase 客户端初始化
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://dpuvnvghlbalwdivxzpc.supabase.co")!,
    supabaseKey: "sb_publishable_Z2zlgDg0cMPGQlSe3cxXiA_SSMizAdb"
)

// MARK: - 测试视图
struct SupabaseTestView: View {
    @State private var isSuccess: Bool? = nil
    @State private var logText: String = "点击按钮开始测试连接..."
    @State private var isTesting: Bool = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 状态图标
                statusIcon

                // 调试日志框
                logView

                // 测试按钮
                testButton
            }
            .padding()
        }
        .navigationTitle("Supabase 连接测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 状态图标
    private var statusIcon: some View {
        Group {
            if let success = isSuccess {
                Image(systemName: success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(success ? ApocalypseTheme.success : ApocalypseTheme.danger)
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 80))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .animation(.easeInOut, value: isSuccess)
    }

    // MARK: - 日志视图
    private var logView: some View {
        ScrollView {
            Text(logText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(height: 200)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 测试按钮
    private var testButton: some View {
        Button(action: testConnection) {
            HStack {
                if isTesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
                Text(isTesting ? "测试中..." : "测试连接")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isTesting ? ApocalypseTheme.textSecondary : ApocalypseTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isTesting)
    }

    // MARK: - 测试连接逻辑
    private func testConnection() {
        isTesting = true
        isSuccess = nil
        logText = "[\(timestamp)] 开始测试连接...\n"
        logText += "[\(timestamp)] URL: https://dpuvnvghlbalwdivxzpc.supabase.co\n"
        logText += "[\(timestamp)] 正在查询测试表...\n"

        Task {
            do {
                // 故意查询一个不存在的表来测试连接
                let _: [EmptyResponse] = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()
                    .value

                // 如果没有抛出错误（不太可能），也算成功
                await MainActor.run {
                    isSuccess = true
                    logText += "[\(timestamp)] ✅ 连接成功（查询返回）\n"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    isTesting = false
                }
            }
        }
    }

    // MARK: - 错误处理
    private func handleError(_ error: Error) {
        let errorString = String(describing: error)
        logText += "[\(timestamp)] 错误详情: \(errorString)\n"

        // 检查是否是 PostgreSQL REST API 错误（说明连接成功，只是表不存在）
        if errorString.contains("PGRST") ||
           errorString.contains("Could not find") ||
           errorString.contains("relation") && errorString.contains("does not exist") ||
           errorString.contains("42P01") {
            // 这些错误说明已经成功连接到 Supabase，只是表不存在
            isSuccess = true
            logText += "[\(timestamp)] ✅ 连接成功（服务器已响应）\n"
            logText += "[\(timestamp)] 说明：表不存在是预期的，证明 Supabase 连接正常\n"
        } else if errorString.contains("hostname") ||
                  errorString.contains("NSURLErrorDomain") ||
                  errorString.contains("Could not connect") ||
                  errorString.contains("network") ||
                  errorString.contains("Internet") {
            // 网络或 URL 错误
            isSuccess = false
            logText += "[\(timestamp)] ❌ 连接失败：URL 错误或无网络\n"
        } else if errorString.contains("Invalid API key") ||
                  errorString.contains("apikey") ||
                  errorString.contains("JWT") {
            // API Key 错误
            isSuccess = false
            logText += "[\(timestamp)] ❌ 连接失败：API Key 无效\n"
        } else {
            // 其他错误 - 可能还是连接成功的
            // 如果收到了服务器响应，即使是错误也算连接成功
            if errorString.contains("PostgrestError") || errorString.contains("code") {
                isSuccess = true
                logText += "[\(timestamp)] ✅ 连接成功（服务器返回错误响应）\n"
            } else {
                isSuccess = false
                logText += "[\(timestamp)] ❌ 未知错误: \(error.localizedDescription)\n"
            }
        }
    }

    // MARK: - 时间戳
    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - 空响应模型
private struct EmptyResponse: Decodable {}

#Preview {
    NavigationStack {
        SupabaseTestView()
    }
}

