import Foundation
import UniformTypeIdentifiers

/// Reads plain text from .txt and .docx files.
/// For .docx, extracts text from the XML inside the ZIP archive — no external dependencies.
struct DocumentReader {

    enum ReadError: LocalizedError {
        case unsupportedFormat
        case readFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat: return "Formato não suportado. Use .txt ou .docx."
            case .readFailed(let msg): return "Falha ao ler: \(msg)"
            }
        }
    }

    /// Read text content from a file URL (.txt or .docx)
    static func readText(from url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "txt", "text", "md":
            return try readPlainText(from: url)
        case "docx":
            return try readDocx(from: url)
        default:
            throw ReadError.unsupportedFormat
        }
    }

    // MARK: — Plain text

    private static func readPlainText(from url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try other encodings
            if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
                return content
            }
            throw ReadError.readFailed(error.localizedDescription)
        }
    }

    // MARK: — DOCX (ZIP → XML → text)

    private static func readDocx(from url: URL) throws -> String {
        // .docx is a ZIP archive. We need to find word/document.xml inside it.
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Unzip using /usr/bin/ditto (built into macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", url.path, tempDir.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ReadError.readFailed("Não foi possível descompactar o arquivo .docx")
        }

        // Read word/document.xml
        let documentXml = tempDir.appendingPathComponent("word/document.xml")
        guard FileManager.default.fileExists(atPath: documentXml.path) else {
            throw ReadError.readFailed("Arquivo .docx inválido (word/document.xml não encontrado)")
        }

        let xmlData = try Data(contentsOf: documentXml)
        let parser = DocxXmlParser()
        return parser.extractText(from: xmlData)
    }
}

// MARK: — DOCX XML Parser

/// Extracts text from <w:t> elements in word/document.xml
private class DocxXmlParser: NSObject, XMLParserDelegate {
    private var extractedText = ""
    private var currentParagraphText = ""
    private var isInsideTextElement = false
    private var paragraphs: [String] = []

    func extractText(from data: Data) -> String {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        // Join paragraphs with newlines
        return paragraphs
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: — XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes: [String : String] = [:]) {
        // <w:t> contains the actual text
        if elementName == "w:t" {
            isInsideTextElement = true
        }
        // <w:p> marks a new paragraph
        if elementName == "w:p" {
            currentParagraphText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideTextElement {
            currentParagraphText += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "w:t" {
            isInsideTextElement = false
        }
        // End of paragraph — add a line
        if elementName == "w:p" {
            paragraphs.append(currentParagraphText)
        }
    }
}
