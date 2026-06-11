import Foundation

final class TemplatePreferences {
    static let appGroupIdentifier = "group.com.xingshuhao.NewFile"

    private let userDefaults: UserDefaults
    private let enabledTemplateIDsKey = "enabledTemplateIDs"

    convenience init() {
        self.init(userDefaults: UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard)
    }

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var enabledTemplateIDs: Set<String> {
        get {
            guard let storedIDs = userDefaults.array(forKey: enabledTemplateIDsKey) as? [String] else {
                return Set(BuiltInTemplates.all.map(\.id))
            }

            let knownIDs = Set(BuiltInTemplates.all.map(\.id))
            return Set(storedIDs).intersection(knownIDs)
        }
        set {
            let sortedIDs = newValue.sorted()
            userDefaults.set(sortedIDs, forKey: enabledTemplateIDsKey)
        }
    }

    func isEnabled(_ template: FileTemplate) -> Bool {
        enabledTemplateIDs.contains(template.id)
    }

    func setEnabled(_ isEnabled: Bool, for template: FileTemplate) {
        var ids = enabledTemplateIDs
        if isEnabled {
            ids.insert(template.id)
        } else {
            ids.remove(template.id)
        }
        enabledTemplateIDs = ids
    }
}
