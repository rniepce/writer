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
            ZenTheme.parchment.ignoresSafeArea()

            VStack(spacing: 0) {
                // Formatting toolbar — above title
                FormattingBar()

                // Chapter title
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

                // Bottom status
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

// MARK: — Formatting Bar (uses responder chain — no coordinator needed)

struct FormattingBar: View {
    var body: some View {
        HStack(spacing: 2) {
            FormatButton(icon: "bold", label: "Negrito (⌘B)") {
                NSApp.sendAction(Selector(("toggleBoldface:")), to: nil, from: nil)
            }
            FormatButton(icon: "italic", label: "Itálico (⌘I)") {
                NSApp.sendAction(Selector(("toggleItalics:")), to: nil, from: nil)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

// MARK: — Format Button

struct FormatButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovering ? ZenTheme.amber : ZenTheme.inkLight.opacity(0.6))
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovering ? ZenTheme.amber.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.borderless)
        .help(label)
        .onHover { isHovering = $0 }
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
                    .onExitCommand { isEditingTitle = false }
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

            if isSaving {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
}
