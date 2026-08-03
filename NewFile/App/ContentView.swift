import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Divider()
            enablementPanel
            privacyPanel
            Spacer(minLength: 0)
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
            HStack {
                Button("setup.open_settings") {
                    ExtensionSettingsOpener.open()
                }
                Button("setup.relaunch_finder") {
                    FinderRelauncher.relaunch()
                }
            }
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

enum FinderRelauncher {
    static func relaunch() {
        let script = "tell application \"Finder\" to quit\n delay 0.5\n tell application \"Finder\" to activate"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}
