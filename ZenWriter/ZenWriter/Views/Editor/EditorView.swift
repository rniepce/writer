import SwiftUI
import SwiftData

struct EditorView: View {
    @Bindable var chapter: Chapter
    @State private var isSaving = false
    @State private var lastSaved: Date?
    @State private var saveTask: Task<Void, Never>?
    @State private var showSavedFeedback = false

    var body: some View {
        ZStack {
            // Full parchment background
            ZenTheme.parchment.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar — ultra minimal
                EditorTopBar(
                    chapter: chapter,
                    isSaving: isSaving,
                    showSavedFeedback: showSavedFeedback
                )

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

                // Bottom status — whisper-quiet
                HStack(spacing: 16) {
                    Text("\(chapter.wordCount) palavras")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(ZenTheme.inkLight.opacity(0.5))

                    Spacer()

                    if let saved = lastSaved {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ZenTheme.saved.opacity(0.6))
                                .frame(width: 5, height: 5)
                            Text(formatSaved(saved))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(ZenTheme.inkLight.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: — Auto-save

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            isSaving = true
            try? chapter.modelContext?.save()
            isSaving = false
            lastSaved = Date()

            // Brief green dot feedback
            withAnimation(.easeIn(duration: 0.2)) { showSavedFeedback = true }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.5)) { showSavedFeedback = false }
        }
    }

    private func formatSaved(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 5 { return "salvo" }
        if diff < 60 { return "há \(Int(diff))s" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

// MARK: — Top Bar

struct EditorTopBar: View {
    @Bindable var chapter: Chapter
    let isSaving: Bool
    let showSavedFeedback: Bool

    @State private var isEditingTitle = false
    @State private var editTitle = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Chapter title — elegant, editable on click
            if isEditingTitle {
                TextField("", text: $editTitle)
                    .textFieldStyle(.plain)
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundStyle(ZenTheme.ink)
                    .focused($titleFocused)
                    .onSubmit {
                        chapter.title = editTitle.isEmpty ? chapter.title : editTitle
                        isEditingTitle = false
                    }
                    .onExitCommand {
                        isEditingTitle = false
                    }
                    .onAppear { titleFocused = true }
            } else {
                Text(chapter.title)
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundStyle(ZenTheme.ink)
                    .onTapGesture {
                        editTitle = chapter.title
                        isEditingTitle = true
                    }
            }

            Spacer()

            // Minimal save indicator
            if isSaving {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}
