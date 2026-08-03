import XCTest

final class UpdateCheckerTests: XCTestCase {
    func testNewerVersionIsDetected() {
        XCTAssertTrue(UpdateChecker.isNewer(latest: "1.1", than: "1.0"))
    }

    func testSameVersionIsNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer(latest: "1.0", than: "1.0"))
    }

    func testOlderVersionIsNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer(latest: "1.0", than: "1.1"))
    }

    // 纯字符串比较会把 "1.10" 判成小于 "1.9"，数值比较不会。
    func testDoubleDigitMinorVersionIsNewer() {
        XCTAssertTrue(UpdateChecker.isNewer(latest: "1.10", than: "1.9"))
    }

    func testUpdateInfoDecodesFromVersionJSON() throws {
        let json = Data("""
        {"version":"1.1","download_url":"https://example.com/releases"}
        """.utf8)

        let info = try JSONDecoder().decode(UpdateInfo.self, from: json)

        XCTAssertEqual(info.version, "1.1")
        XCTAssertEqual(info.downloadURL, URL(string: "https://example.com/releases"))
    }
}
