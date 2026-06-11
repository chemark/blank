import Foundation

struct FileTemplate: Identifiable, Hashable {
    let id: String
    let displayName: String
    let fileExtension: String

    var defaultFileName: String {
        "Untitled.\(fileExtension)"
    }
}

enum BuiltInTemplates {
    static let all: [FileTemplate] = [
        FileTemplate(id: "txt", displayName: "Text File", fileExtension: "txt"),
        FileTemplate(id: "md", displayName: "Markdown File", fileExtension: "md"),
        FileTemplate(id: "json", displayName: "JSON File", fileExtension: "json"),
        FileTemplate(id: "csv", displayName: "CSV File", fileExtension: "csv"),
        FileTemplate(id: "html", displayName: "HTML File", fileExtension: "html"),
    ]

    static func template(for id: String) -> FileTemplate? {
        all.first { $0.id == id }
    }
}
