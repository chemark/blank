import Foundation

// 放在 Shared 而不是 App 下，是因为测试 target 只编译 Tests 和 Shared。
// 扩展 target 也会编译到这个文件，但不会调用它，扩展的 entitlements 里也没有
// network.client，「扩展不联网」这一点不受影响。

struct UpdateInfo: Decodable, Equatable {
    let version: String
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case version
        case downloadURL = "download_url"
    }
}

enum UpdateChecker {
    /// 用数值方式比较版本号，避免 "1.10" 被判成小于 "1.9"。
    static func isNewer(latest: String, than current: String) -> Bool {
        latest.compare(current, options: .numeric) == .orderedDescending
    }

    static func fetchLatest(from url: URL) async throws -> UpdateInfo {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UpdateInfo.self, from: data)
    }
}
