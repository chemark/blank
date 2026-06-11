import XCTest

final class FileCreationServiceTests: XCTestCase {
    func testAvailableURLUsesUntitledWhenNoConflict() throws {
        let directory = try temporaryDirectory()
        let service = FileCreationService()
        let url = try service.availableURL(for: BuiltInTemplates.all[1], in: directory)

        XCTAssertEqual(url.lastPathComponent, "Untitled.md")
    }

    func testAvailableURLAddsNumberWhenFileExists() throws {
        let directory = try temporaryDirectory()
        FileManager.default.createFile(
            atPath: directory.appendingPathComponent("Untitled.md").path,
            contents: Data()
        )
        FileManager.default.createFile(
            atPath: directory.appendingPathComponent("Untitled 2.md").path,
            contents: Data()
        )

        let service = FileCreationService()
        let url = try service.availableURL(for: BuiltInTemplates.all[1], in: directory)

        XCTAssertEqual(url.lastPathComponent, "Untitled 3.md")
    }

    func testCreateEmptyFileWritesZeroByteFile() throws {
        let directory = try temporaryDirectory()
        let service = FileCreationService()
        let url = try service.createEmptyFile(template: BuiltInTemplates.all[0], in: directory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        XCTAssertEqual(data.count, 0)
    }

    func testAvailableUntitledFileURLHasNoExtension() throws {
        let directory = try temporaryDirectory()
        let service = FileCreationService()
        let url = try service.availableUntitledFileURL(in: directory)

        XCTAssertEqual(url.lastPathComponent, "Untitled")
        XCTAssertEqual(url.pathExtension, "")
    }

    func testAvailableUntitledFileURLAddsNumberWhenFileExists() throws {
        let directory = try temporaryDirectory()
        FileManager.default.createFile(
            atPath: directory.appendingPathComponent("Untitled").path,
            contents: Data()
        )
        FileManager.default.createFile(
            atPath: directory.appendingPathComponent("Untitled 2").path,
            contents: Data()
        )

        let service = FileCreationService()
        let url = try service.availableUntitledFileURL(in: directory)

        XCTAssertEqual(url.lastPathComponent, "Untitled 3")
        XCTAssertEqual(url.pathExtension, "")
    }

    func testCreateUntitledFileWritesZeroByteFile() throws {
        let directory = try temporaryDirectory()
        let service = FileCreationService()
        let url = try service.createUntitledFile(in: directory)

        XCTAssertEqual(url.lastPathComponent, "Untitled")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        XCTAssertEqual(data.count, 0)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NewFileTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }
}
