import Foundation
import SwiftData

@Model
final class Chapter {
    var title: String
    var content: String
    var order: Int
    var wordCount: Int
    var color: String?
    var createdAt: Date
    var updatedAt: Date

    var project: Project?

    init(
        title: String = "Novo Capítulo",
        content: String = "",
        order: Int = 0,
        color: String? = nil,
        project: Project? = nil
    ) {
        self.title = title
        self.content = content
        self.order = order
        self.wordCount = Self.countWords(content)
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
    }

    static func countWords(_ text: String) -> Int {
        // Extract plain text from RTF if needed
        let plainText: String
        if text.hasPrefix("{\\rtf"), let data = text.data(using: .utf8),
           let attrStr = NSAttributedString(rtf: data, documentAttributes: nil) {
            plainText = attrStr.string
        } else {
            plainText = text
        }
        let trimmed = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    func updateContent(_ newContent: String) {
        self.content = newContent
        self.wordCount = Self.countWords(newContent)
        self.updatedAt = Date()
    }
}
