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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Projetos", systemImage: "book.closed.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: { isAddingProject.toggle() }) {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderless)
                .help("Novo projeto")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // New project form
            if isAddingProject {
                HStack(spacing: 8) {
                    TextField("Nome do projeto…", text: $newProjectTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { createProject() }
                    Button("Criar") { createProject() }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .disabled(newProjectTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(action: { isAddingProject = false; newProjectTitle = "" }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
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
                            Button("Excluir", role: .destructive) {
                                deleteProject(project)
                            }
                        }
                }
                .onDelete(perform: deleteProjects)
            }
            .listStyle(.sidebar)
            .frame(minHeight: 120, maxHeight: 250)

            // Import button
            Button(action: { isImporting = true }) {
                Label("Importar Projeto", systemImage: "square.and.arrow.down")
                    .font(.subheadline)
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

        // Create first chapter
        let chapter = Chapter(title: "Capítulo 1", order: 0, project: project)
        modelContext.insert(chapter)

        try? modelContext.save()

        selectedProject = project
        selectedChapter = chapter
        newProjectTitle = ""
        isAddingProject = false
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
        for i in offsets {
            deleteProject(projects[i])
        }
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
            Image(systemName: "book.fill")
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.body)
                    .lineLimit(1)
                Text("\(project.chapters.count) capítulo\(project.chapters.count != 1 ? "s" : "") · \(project.totalWordCount) palavras")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
