import SwiftUI
import AppKit

struct ContentView: View {
    @State private var updateStatusKey: String?
    @State private var isCheckingUpdate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Divider()
            enablementPanel
            privacyPanel
            Spacer(minLength: 0)
            updateRow
        }
        .padding(28)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "Blank")
                .font(.largeTitle.weight(.semibold))
            Text("app.subtitle")
                .foregroundStyle(.secondary)
        }
    }

    private var enablementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("setup.title", systemImage: "puzzlepiece.extension")
                .font(.headline)
            Text("setup.body")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("setup.open_settings") {
                ExtensionSettingsOpener.open()
            }
            Text("setup.troubleshoot")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("privacy.title", systemImage: "lock.shield")
                .font(.headline)
            Text("privacy.body")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var updateRow: some View {
        HStack(spacing: 10) {
            Button("update.check") {
                Task { await checkForUpdates() }
            }
            .disabled(isCheckingUpdate)
            if let updateStatusKey {
                Text(LocalizedStringKey(updateStatusKey))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private static let versionManifestURL = URL(string: "https://blank.hoshikihao.com/version.json")!

    private func checkForUpdates() async {
        isCheckingUpdate = true
        updateStatusKey = "update.checking"
        defer { isCheckingUpdate = false }

        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

        do {
            let info = try await UpdateChecker.fetchLatest(from: Self.versionManifestURL)
            if UpdateChecker.isNewer(latest: info.version, than: current) {
                updateStatusKey = "update.available"
                NSWorkspace.shared.open(info.downloadURL)
            } else {
                updateStatusKey = "update.up_to_date"
            }
        } catch {
            updateStatusKey = "update.failed"
        }
    }
}

enum ExtensionSettingsOpener {
    static func open() {
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?Finder"),
            URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"),
        ].compactMap { $0 }

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }
}
