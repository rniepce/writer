import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var selectedProject: Project?
    @State private var selectedChapter: Chapter?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // MARK: — Sidebar
            SidebarView(
                selectedProject: $selectedProject,
                selectedChapter: $selectedChapter
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            // MARK: — Detail (Editor)
            if let chapter = selectedChapter {
                EditorView(chapter: chapter)
            } else if selectedProject != nil {
                VStack(spacing: 16) {
                    Image(systemName: "text.page")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Selecione ou crie um capítulo")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)
                    Text("ZenWriter")
                        .font(.largeTitle)
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    Text("Selecione ou crie um projeto para começar")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
        .onAppear {
            // Auto-select first project if none selected
            if selectedProject == nil, let first = projects.first {
                selectedProject = first
                selectedChapter = first.sortedChapters.first
            }
        }
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
                Divider()
                ChapterListView(
                    project: project,
                    selectedChapter: $selectedChapter
                )
            }
        }
    }
}
