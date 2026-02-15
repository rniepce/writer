import Foundation
import SwiftData

@Model
final class ReferenceDoc {
    var docType: String  // "narrative_map" or "writing_style"
    var content: String
    var filename: String?
    var createdAt: Date
    var updatedAt: Date

    var project: Project?

    init(
        docType: String,
        content: String = "",
        filename: String? = nil,
        project: Project? = nil
    ) {
        self.docType = docType
        self.content = content
        self.filename = filename
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
    }
}
