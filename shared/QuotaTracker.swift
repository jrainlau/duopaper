import Foundation
import Observation

/// 跟踪 Unsplash API 的每小时请求配额（来自响应头 X-RateLimit-*）。
/// 默认不对外展示；只有配额耗尽时，发现页才在刷新按钮旁弹气泡提示。
@MainActor
@Observable
final class QuotaTracker {
    static let shared = QuotaTracker()

    private(set) var limit: Int?
    private(set) var remaining: Int?
    /// 本小时窗口内配额是否已耗尽：403/429，或 remaining 归零。成功且有余量时自动复位。
    private(set) var exhausted = false

    /// 调用方（UnsplashClient.fetch）通过 MainActor.run 调到这里，保证记录先于调用方检查 exhausted。
    func record(statusCode: Int, remaining: Int?, limit: Int?) {
        if let remaining, let limit {
            self.remaining = remaining
            self.limit = limit
            exhausted = remaining <= 0
        }
        if statusCode == 403 || statusCode == 429 {
            exhausted = true
        }
    }
}
