import Foundation
import SwiftData

@Model
final class Project {
    var title: String
    var descriptionText: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Chapter.project)
    var chapters: [Chapter] = []

    @Relationship(deleteRule: .cascade, inverse: \ReferenceDoc.project)
    var referenceDocs: [ReferenceDoc] = []

    init(title: String, descriptionText: String? = nil) {
        self.title = title
        self.descriptionText = descriptionText
        self.createdAt = Date()
    }

    var sortedChapters: [Chapter] {
        chapters.sorted { $0.order < $1.order }
    }

    var totalWordCount: Int {
        chapters.reduce(0) { $0 + $1.wordCount }
    }
}
