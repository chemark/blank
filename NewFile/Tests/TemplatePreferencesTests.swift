import XCTest

final class TemplatePreferencesTests: XCTestCase {
    func testDefaultsToAllBuiltInTemplates() {
        let defaults = UserDefaults(suiteName: "NewFileTests-\(UUID().uuidString)")!
        let preferences = TemplatePreferences(userDefaults: defaults)

        XCTAssertEqual(preferences.enabledTemplateIDs, Set(BuiltInTemplates.all.map(\.id)))
    }

    func testStoresEnabledTemplateIDs() {
        let defaults = UserDefaults(suiteName: "NewFileTests-\(UUID().uuidString)")!
        let preferences = TemplatePreferences(userDefaults: defaults)

        preferences.enabledTemplateIDs = ["md", "json"]

        XCTAssertEqual(preferences.enabledTemplateIDs, ["md", "json"])
    }

    func testIgnoresUnknownStoredTemplateIDs() {
        let defaults = UserDefaults(suiteName: "NewFileTests-\(UUID().uuidString)")!
        defaults.set(["md", "unknown"], forKey: "enabledTemplateIDs")

        let preferences = TemplatePreferences(userDefaults: defaults)

        XCTAssertEqual(preferences.enabledTemplateIDs, ["md"])
    }
}
