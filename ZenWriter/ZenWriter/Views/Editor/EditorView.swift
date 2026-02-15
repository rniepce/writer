import SwiftUI
import SwiftData

struct EditorView: View {
    @Bindable var chapter: Chapter
    @State private var isSaving = false
    @State private var lastSaved: Date?
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            EditorToolbar(chapter: chapter, isSaving: isSaving, lastSaved: lastSaved)

            // Editor
            RichTextEditor(
                text: Binding(
                    get: { chapter.content },
                    set: { newValue in
                        chapter.updateContent(newValue)
                        scheduleSave()
                    }
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom bar
            HStack {
                Text("\(chapter.wordCount) palavras")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let saved = lastSaved {
                    Text(formatSaved(saved))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    // MARK: — Auto-save

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            isSaving = true
            // SwiftData auto-saves, but we explicitly save for safety
            try? chapter.modelContext?.save()
            isSaving = false
            lastSaved = Date()
        }
    }

    private func formatSaved(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 5 { return "Salvo agora" }
        if diff < 60 { return "Salvo há \(Int(diff))s" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "Salvo às \(fmt.string(from: date))"
    }
}

// MARK: — Editor Toolbar

struct EditorToolbar: View {
    @Bindable var chapter: Chapter
    let isSaving: Bool
    let lastSaved: Date?

    @State private var isEditingTitle = false
    @State private var editTitle = ""

    var body: some View {
        HStack(spacing: 12) {
            // Chapter title (editable)
            if isEditingTitle {
                TextField("Título do capítulo", text: $editTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.weight(.medium))
                    .frame(maxWidth: 400)
                    .onSubmit {
                        chapter.title = editTitle
                        isEditingTitle = false
                    }
                    .onExitCommand {
                        isEditingTitle = false
                    }
            } else {
                Text(chapter.title)
                    .font(.title3.weight(.medium))
                    .onTapGesture {
                        editTitle = chapter.title
                        isEditingTitle = true
                    }
            }

            Spacer()

            // Save status
            if isSaving {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Salvando…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
