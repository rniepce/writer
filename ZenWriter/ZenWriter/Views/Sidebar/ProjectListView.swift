import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Binding var selectedProject: Project?
    @Binding var selectedChapter: Chapter?

    @State private var isAddingProject = false
    @State private var newProjectTitle = ""
    @State private var isImporting = false
    @FocusState private var newProjectFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Projetos")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) { isAddingProject.toggle() }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Novo projeto")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // New project inline form
            if isAddingProject {
                HStack(spacing: 6) {
                    TextField("Título do projeto…", text: $newProjectTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body))
                        .focused($newProjectFocused)
                        .onSubmit { createProject() }
                        .onExitCommand {
                            isAddingProject = false
                            newProjectTitle = ""
                        }
                    Button(action: createProject) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(ZenTheme.amber, in: Circle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(newProjectTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .onAppear { newProjectFocused = true }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            // Project list
            List(selection: Binding(
                get: { selectedProject?.persistentModelID },
                set: { id in
                    if let id, let proj = projects.first(where: { $0.persistentModelID == id }) {
                        selectedProject = proj
                        selectedChapter = proj.sortedChapters.first
                    }
                }
            )) {
                ForEach(projects) { project in
                    ProjectRow(project: project, isSelected: project === selectedProject)
                        .tag(project.persistentModelID)
                        .contextMenu {
                            Button("Exportar…") { ImportExportService.exportProject(project) }
                            Divider()
                            Button("Excluir", role: .destructive) { deleteProject(project) }
                        }
                }
                .onDelete(perform: deleteProjects)
            }
            .listStyle(.sidebar)
            .frame(minHeight: 100, maxHeight: 220)

            // Import button — subtle
            Button(action: { isImporting = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 11))
                    Text("Importar Projeto")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
    }

    // MARK: — Actions

    private func createProject() {
        let title = newProjectTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        let project = Project(title: title)
        modelContext.insert(project)

        let chapter = Chapter(title: "Capítulo 1", order: 0, project: project)
        modelContext.insert(chapter)

        try? modelContext.save()

        selectedProject = project
        selectedChapter = chapter
        newProjectTitle = ""
        withAnimation { isAddingProject = false }
    }

    private func deleteProject(_ project: Project) {
        let wasSelected = (project === selectedProject)
        modelContext.delete(project)
        try? modelContext.save()

        if wasSelected {
            selectedProject = projects.first(where: { $0 !== project })
            selectedChapter = selectedProject?.sortedChapters.first
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for i in offsets { deleteProject(projects[i]) }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        ImportExportService.importProject(from: url, into: modelContext) { imported in
            if let imported {
                selectedProject = imported
                selectedChapter = imported.sortedChapters.first
            }
        }
    }
}

// MARK: — Project Row

struct ProjectRow: View {
    let project: Project
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "book.fill" : "book.closed")
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? ZenTheme.amber : .secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(project.title)
                    .font(.system(.body))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(project.chapters.count) cap. · \(project.totalWordCount) palavras")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
    }
}
