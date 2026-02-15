import Foundation
import SwiftData
import AppKit

/// Handles import/export of `.writerproject` JSON bundles.
/// Compatible with the existing web/Tauri format.
struct ImportExportService {

    // MARK: — Export

    struct ExportBundle: Codable {
        let version: String
        let project: ProjectData
        let chapters: [ChapterData]
        let references: [ReferenceData]
    }

    struct ProjectData: Codable {
        let title: String
        let description: String?
    }

    struct ChapterData: Codable {
        let title: String
        let content: String
        let order: Int
        let word_count: Int
        let color: String?
    }

    struct ReferenceData: Codable {
        let doc_type: String
        let content: String
        let filename: String?
    }

    /// Export a project to a `.writerproject` JSON file via NSSavePanel.
    static func exportProject(_ project: Project) {
        let bundle = ExportBundle(
            version: "1.0",
            project: ProjectData(
                title: project.title,
                description: project.descriptionText
            ),
            chapters: project.sortedChapters.map { ch in
                ChapterData(
                    title: ch.title,
                    content: ch.content,
                    order: ch.order,
                    word_count: ch.wordCount,
                    color: ch.color
                )
            },
            references: project.referenceDocs.map { ref in
                ReferenceData(
                    doc_type: ref.docType,
                    content: ref.content,
                    filename: ref.filename
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(bundle) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(project.title).writerproject"
        panel.title = "Salvar Projeto"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        try? data.write(to: url)
    }

    // MARK: — Import

    /// Import a `.writerproject` JSON file into SwiftData.
    static func importProject(from url: URL, into context: ModelContext, completion: @escaping (Project?) -> Void) {
        guard url.startAccessingSecurityScopedResource() else {
            completion(nil)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            completion(nil)
            return
        }

        let decoder = JSONDecoder()
        guard let bundle = try? decoder.decode(ExportBundle.self, from: data) else {
            completion(nil)
            return
        }

        let project = Project(
            title: bundle.project.title,
            descriptionText: bundle.project.description
        )
        context.insert(project)

        for chData in bundle.chapters {
            let chapter = Chapter(
                title: chData.title,
                content: chData.content,
                order: chData.order,
                color: chData.color,
                project: project
            )
            chapter.wordCount = chData.word_count
            context.insert(chapter)
        }

        for refData in bundle.references {
            let ref = ReferenceDoc(
                docType: refData.doc_type,
                content: refData.content,
                filename: refData.filename,
                project: project
            )
            context.insert(ref)
        }

        try? context.save()
        completion(project)
    }
}
