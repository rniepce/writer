import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ReferenceDocsView: View {
    @Environment(\.modelContext) private var modelContext
    let project: Project

    var narrativeMap: ReferenceDoc? {
        project.referenceDocs.first(where: { $0.docType == "narrative_map" })
    }

    var writingStyle: ReferenceDoc? {
        project.referenceDocs.first(where: { $0.docType == "writing_style" })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Referências")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Doc sections
            VStack(spacing: 6) {
                DocSlot(
                    title: "Mapa Narrativo",
                    icon: "map",
                    doc: narrativeMap,
                    docType: "narrative_map",
                    project: project
                )

                DocSlot(
                    title: "Estilo de Escrita",
                    icon: "textformat",
                    doc: writingStyle,
                    docType: "writing_style",
                    project: project
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: — Document Slot

struct DocSlot: View {
    let title: String
    let icon: String
    let doc: ReferenceDoc?
    let docType: String
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false
    @State private var isExpanded = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var hasDoc: Bool { doc != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(hasDoc ? ZenTheme.amber : Color.gray.opacity(0.4))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                    if let doc = doc, let filename = doc.filename {
                        Text(filename)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if hasDoc {
                    // Preview toggle
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)

                    // Delete
                    Button(action: deleteDoc) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                    .help("Remover documento")
                } else {
                    // Upload
                    Button(action: { isImporting = true }) {
                        Image(systemName: "arrow.up.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Enviar .txt ou .docx")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hasDoc ? ZenTheme.amber.opacity(0.06) : Color.clear)
            )

            // Expanded preview
            if isExpanded, let doc = doc {
                ScrollView {
                    Text(doc.content.prefix(2000) + (doc.content.count > 2000 ? "\n\n[…]" : ""))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 150)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [
                UTType.plainText,
                UTType(filenameExtension: "docx") ?? .data
            ],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Erro", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Erro desconhecido")
        }
    }

    // MARK: — Actions

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try DocumentReader.readText(from: url)

            // Remove existing doc of this type
            if let existing = doc {
                modelContext.delete(existing)
            }

            let newDoc = ReferenceDoc(
                docType: docType,
                content: content,
                filename: url.lastPathComponent,
                project: project
            )
            modelContext.insert(newDoc)
            try modelContext.save()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func deleteDoc() {
        guard let doc = doc else { return }
        withAnimation {
            modelContext.delete(doc)
            try? modelContext.save()
            isExpanded = false
        }
    }
}
