import Cocoa
import FinderSync
import os

final class FinderSync: FIFinderSync {
    private let preferences = TemplatePreferences()
    private let fileCreationService = FileCreationService()
    private let logger = Logger(subsystem: "com.xingshuhao.NewFile.finder-extension", category: "FinderSync")

    override init() {
        super.init()

        FIFinderSyncController.default().directoryURLs = monitoredDirectoryURLs()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "New File")

        let item = NSMenuItem(
            title: "New File",
            action: #selector(createUntitledFile(_:)),
            keyEquivalent: ""
        )
        item.target = self
        menu.addItem(item)

        return menu
    }

    @objc private func createUntitledFile(_ sender: NSMenuItem) {
        guard let directoryURL = targetDirectoryURL() else {
            logger.error("New File failed: no target directory")
            NSSound.beep()
            return
        }

        do {
            logger.info("Creating untitled file in \(directoryURL.path, privacy: .public)")
            let createdURL = try fileCreationService.createUntitledFile(in: directoryURL)
            NSWorkspace.shared.activateFileViewerSelecting([createdURL])
        } catch {
            logger.error("New File failed in \(directoryURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            NSSound.beep()
        }
    }

    private func targetDirectoryURL() -> URL? {
        let controller = FIFinderSyncController.default()

        if let targetedURL = controller.targetedURL() {
            if targetedURL.isDirectory {
                return targetedURL
            }
            return targetedURL.deletingLastPathComponent()
        }

        if let selectedDirectory = controller.selectedItemURLs()?.first(where: { $0.isDirectory }) {
            return selectedDirectory
        }

        if let selectedItem = controller.selectedItemURLs()?.first {
            return selectedItem.deletingLastPathComponent()
        }

        return nil
    }

    private func monitoredDirectoryURLs() -> Set<URL> {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        var urls: Set<URL> = [
            home,
            URL(fileURLWithPath: "/", isDirectory: true),
        ]

        for directory in FileManager.SearchPathDirectory.allUserVisibleDirectories {
            if let url = fileManager.urls(for: directory, in: .userDomainMask).first {
                urls.insert(url)
            }
        }

        return urls
    }
}

private extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}

private extension FileManager.SearchPathDirectory {
    static let allUserVisibleDirectories: [FileManager.SearchPathDirectory] = [
        .desktopDirectory,
        .documentDirectory,
        .downloadsDirectory,
        .moviesDirectory,
        .musicDirectory,
        .picturesDirectory,
    ]
}
