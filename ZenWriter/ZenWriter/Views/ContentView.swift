import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var selectedProject: Project?
    @State private var selectedChapter: Chapter?
    @State private var sidebarVisible = true

    var body: some View {
        NavigationSplitView(columnVisibility: Binding(
            get: { sidebarVisible ? .all : .detailOnly },
            set: { sidebarVisible = ($0 != .detailOnly) }
        )) {
            // MARK: — Sidebar
            SidebarView(
                selectedProject: $selectedProject,
                selectedChapter: $selectedChapter
            )
            .navigationSplitViewColumnWidth(
                min: ZenTheme.sidebarMinWidth,
                ideal: ZenTheme.sidebarIdealWidth,
                max: ZenTheme.sidebarMaxWidth
            )
        } detail: {
            // MARK: — Detail
            if let chapter = selectedChapter {
                EditorView(chapter: chapter)
                    .id(chapter.persistentModelID)
            } else if selectedProject != nil {
                emptyChapterState
            } else {
                welcomeState
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { withAnimation(.easeInOut(duration: 0.25)) { sidebarVisible.toggle() } }) {
                    Image(systemName: "sidebar.left")
                        .foregroundStyle(ZenTheme.inkLight)
                }
                .help(sidebarVisible ? "Esconder sidebar" : "Mostrar sidebar")
            }
        }
        .onAppear {
            if selectedProject == nil, let first = projects.first {
                selectedProject = first
                selectedChapter = first.sortedChapters.first
            }
        }
    }

    // MARK: — Empty States

    private var emptyChapterState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.cursor")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(ZenTheme.divider)
            Text("Selecione ou crie um capítulo")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(ZenTheme.inkLight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ZenTheme.parchment)
    }

    private var welcomeState: some View {
        VStack(spacing: 24) {
            // Feather icon
            Image(systemName: "pencil.line")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(ZenTheme.amber.opacity(0.5))

            VStack(spacing: 8) {
                Text("ZenWriter")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundStyle(ZenTheme.ink)
                Text("Escreva sem distrações")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(ZenTheme.inkLight)
            }

            // Decorative line
            Rectangle()
                .fill(ZenTheme.divider)
                .frame(width: 60, height: 1)
                .padding(.vertical, 4)

            Text("Crie um projeto na barra lateral para começar")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(ZenTheme.inkLight.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ZenTheme.parchment)
    }
}

// MARK: — Sidebar Container

struct SidebarView: View {
    @Binding var selectedProject: Project?
    @Binding var selectedChapter: Chapter?

    var body: some View {
        VStack(spacing: 0) {
            ProjectListView(
                selectedProject: $selectedProject,
                selectedChapter: $selectedChapter
            )

            if let project = selectedProject {
                Rectangle()
                    .fill(ZenTheme.divider)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                ChapterListView(
                    project: project,
                    selectedChapter: $selectedChapter
                )
            }
        }
        .background(ZenTheme.sidebarBg)
    }
}
