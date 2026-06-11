import Foundation

enum FileCreationError: LocalizedError, Equatable {
    case targetIsNotDirectory(URL)
    case templateUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .targetIsNotDirectory(let url):
            "The target is not a folder: \(url.path)"
        case .templateUnavailable(let id):
            "The template is unavailable: \(id)"
        }
    }
}

struct FileCreationService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func availableUntitledFileURL(in directoryURL: URL) throws -> URL {
        try availableURL(baseName: "Untitled", fileExtension: nil, in: directoryURL)
    }

    private func availableURL(baseName: String, fileExtension: String?, in directoryURL: URL) throws -> URL {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw FileCreationError.targetIsNotDirectory(directoryURL)
        }

        let suffix = fileExtension.map { ".\($0)" } ?? ""
        let firstCandidate = directoryURL.appendingPathComponent("\(baseName)\(suffix)", isDirectory: false)
        if !fileManager.fileExists(atPath: firstCandidate.path) {
            return firstCandidate
        }

        var index = 2
        while true {
            let candidate = directoryURL.appendingPathComponent("\(baseName) \(index)\(suffix)", isDirectory: false)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }

    @discardableResult
    func createUntitledFile(in directoryURL: URL) throws -> URL {
        let targetURL = try availableUntitledFileURL(in: directoryURL)
        let data = Data()
        try data.write(to: targetURL, options: [.withoutOverwriting])
        return targetURL
    }
}
