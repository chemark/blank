import XCTest

/// 锁定 Finder Sync 扩展的两条 entitlements 硬约束。
/// 这两条是反复 A/B 验证出来的，删掉任何一条扩展都会静默失效，不会有编译或运行时报错。
final class EntitlementsTests: XCTestCase {
    /// 未沙盒的 Finder Sync 扩展，`pluginkit -a` 会静默拒绝注册：没有报错，只是 (no matches)。
    /// 与 App Store / Developer ID 分发方式无关，沙盒不能去掉。
    func testFinderExtensionIsSandboxed() throws {
        let entitlements = try finderExtensionEntitlements()

        XCTAssertEqual(
            entitlements["com.apple.security.app-sandbox"] as? Bool,
            true,
            "Finder Sync 扩展必须开启 app-sandbox，否则 pluginkit -a 静默拒绝注册"
        )
    }

    /// 扩展沙盒之后，`files.user-selected.read-write` 不足以写入用户右键点击的目录，
    /// 必须保留对 "/" 的临时例外。App Store 审核时需要在备注里说明理由。
    func testFinderExtensionHasAbsolutePathTemporaryException() throws {
        let entitlements = try finderExtensionEntitlements()
        let key = "com.apple.security.temporary-exception.files.absolute-path.read-write"

        XCTAssertEqual(
            entitlements[key] as? [String],
            ["/"],
            "沙盒扩展需要 absolute-path 临时例外才能在右键的文件夹里创建文件"
        )
    }

    private func finderExtensionEntitlements() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // NewFile/Tests
            .deletingLastPathComponent() // NewFile
            .appendingPathComponent("NewFileFinderExtension.entitlements")
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any], "entitlements 不是字典：\(url.path)")
    }
}
