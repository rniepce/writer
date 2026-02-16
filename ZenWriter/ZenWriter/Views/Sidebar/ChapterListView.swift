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
                Text("Capítulos")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ZenTheme.inkLight)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("\(chapters.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(ZenTheme.inkLight.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ZenTheme.divider.opacity(0.5), in: Capsule())
                Button(action: createChapter) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ZenTheme.inkLight)
                }
                .buttonStyle(.borderless)
                .help("Novo capítulo")
                .disabled(isCreating)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

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
                        .listRowBackground(
                            chapter === selectedChapter
                                ? ZenTheme.amberLight.clipShape(RoundedRectangle(cornerRadius: 6))
                                : Color.clear.clipShape(RoundedRectangle(cornerRadius: 6))
                        )
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
            .scrollContentBackground(.hidden)
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
        for i in offsets { deleteChapter(sorted[i]) }
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
            // Subtle accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? ZenTheme.amber : ZenTheme.divider)
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(ZenTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(chapter.wordCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(ZenTheme.inkLight.opacity(0.5))

                    if let preview = chapter.preview {
                        Text("· \(preview)")
                            .font(.system(size: 10))
                            .foregroundStyle(ZenTheme.inkLight.opacity(0.4))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: — Chapter Preview

extension Chapter {
    var preview: String? {
        let clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let maxChars = 40
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
