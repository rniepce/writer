import SwiftUI
import SwiftData

struct ChapterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @Binding var selectedChapter: Chapter?

    @State private var isCreating = false

    var chapters: [Chapter] {
        project.sortedChapters
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Capítulos", systemImage: "list.bullet")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(chapters.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
                Button(action: createChapter) {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderless)
                .help("Novo capítulo")
                .disabled(isCreating)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Chapter list
            List(selection: Binding(
                get: { selectedChapter?.persistentModelID },
                set: { id in
                    if let id, let ch = chapters.first(where: { $0.persistentModelID == id }) {
                        selectedChapter = ch
                    }
                }
            )) {
                ForEach(chapters) { chapter in
                    ChapterRow(chapter: chapter, isSelected: chapter === selectedChapter)
                        .tag(chapter.persistentModelID)
                        .contextMenu {
                            Button("Excluir", role: .destructive) {
                                deleteChapter(chapter)
                            }
                        }
                }
                .onDelete(perform: deleteChapters)
                .onMove(perform: moveChapters)
            }
            .listStyle(.sidebar)
        }
    }

    // MARK: — Actions

    private func createChapter() {
        isCreating = true
        let nextOrder = (chapters.map(\.order).max() ?? -1) + 1
        let chapter = Chapter(
            title: "Capítulo \(chapters.count + 1)",
            order: nextOrder,
            project: project
        )
        modelContext.insert(chapter)
        try? modelContext.save()
        selectedChapter = chapter
        isCreating = false
    }

    private func deleteChapter(_ chapter: Chapter) {
        let wasSelected = (chapter === selectedChapter)
        modelContext.delete(chapter)
        try? modelContext.save()

        if wasSelected {
            selectedChapter = chapters.first(where: { $0 !== chapter })
        }
    }

    private func deleteChapters(at offsets: IndexSet) {
        let sorted = chapters
        for i in offsets {
            deleteChapter(sorted[i])
        }
    }

    private func moveChapters(from source: IndexSet, to destination: Int) {
        var items = chapters
        items.move(fromOffsets: source, toOffset: destination)
        for (idx, chapter) in items.enumerated() {
            chapter.order = idx
        }
        try? modelContext.save()
    }
}

// MARK: — Chapter Row

struct ChapterRow: View {
    let chapter: Chapter
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(chapterColor)
                .frame(width: 4, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(chapter.wordCount) palavras")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let preview = chapter.preview {
                        Text(preview)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var chapterColor: Color {
        if let hex = chapter.color {
            return Color(hex: hex)
        }
        return isSelected ? Color.accentColor : .secondary.opacity(0.3)
    }
}

// MARK: — Chapter Preview Extension

extension Chapter {
    var preview: String? {
        let clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let maxChars = 60
        if clean.count <= maxChars { return clean }
        return String(clean.prefix(maxChars)) + "…"
    }
}

// MARK: — Color from Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
