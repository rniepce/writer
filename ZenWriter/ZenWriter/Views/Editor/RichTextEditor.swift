import SwiftUI
import AppKit

/// A native macOS rich text editor wrapping NSTextView.
/// Stores content as RTF string. Falls back to plain text for backward compatibility.
struct RichTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // — Rich text mode
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.usesFindPanel = true
        textView.usesFindBar = true

        // — Default paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = ZenTheme.editorLineSpacing
        paragraphStyle.paragraphSpacing = ZenTheme.editorParagraphSpacing
        paragraphStyle.alignment = .natural
        textView.defaultParagraphStyle = paragraphStyle

        // — Default typing attributes
        textView.typingAttributes = Self.bodyAttributes(paragraphStyle: paragraphStyle)

        // — Generous margins
        textView.textContainerInset = NSSize(
            width: ZenTheme.editorHorizontalInset,
            height: ZenTheme.editorVerticalInset
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: ZenTheme.editorMaxWidth,
            height: CGFloat.greatestFiniteMagnitude
        )

        // — Warm parchment background
        textView.backgroundColor = ZenTheme.nsParchment
        textView.drawsBackground = true

        // — Amber cursor and selection
        textView.insertionPointColor = NSColor(red: 0.76, green: 0.55, blue: 0.20, alpha: 1.0)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(red: 0.76, green: 0.55, blue: 0.20, alpha: 0.15),
            .foregroundColor: ZenTheme.nsInk
        ]

        // Load initial content
        loadContent(into: textView)
        textView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Only update if text changed externally (chapter switch)
        if !context.coordinator.isEditing {
            let currentRtf = Self.rtfString(from: textView)
            if currentRtf != text {
                loadContent(into: textView)
            }
        }
    }

    // MARK: — RTF Serialization

    /// Load RTF or plain text into the text view
    private func loadContent(into textView: NSTextView) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = ZenTheme.editorLineSpacing
        paragraphStyle.paragraphSpacing = ZenTheme.editorParagraphSpacing

        if text.hasPrefix("{\\rtf"), let data = text.data(using: .utf8) {
            if let attrStr = NSAttributedString(rtf: data, documentAttributes: nil) {
                textView.textStorage?.setAttributedString(attrStr)
                let range = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
                textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                textView.textStorage?.addAttribute(.foregroundColor, value: ZenTheme.nsInk, range: range)
                return
            }
        }

        // Plain text fallback
        textView.string = text
        let range = NSRange(location: 0, length: textView.string.count)
        textView.textStorage?.setAttributes(Self.bodyAttributes(paragraphStyle: paragraphStyle), range: range)
    }

    /// Extract RTF string from the text view
    static func rtfString(from textView: NSTextView) -> String {
        let range = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
        guard let data = textView.textStorage?.rtf(from: range, documentAttributes: [:]) else {
            return textView.string
        }
        return String(data: data, encoding: .utf8) ?? textView.string
    }

    /// Default body text attributes
    static func bodyAttributes(paragraphStyle: NSParagraphStyle? = nil) -> [NSAttributedString.Key: Any] {
        let ps = paragraphStyle ?? {
            let p = NSMutableParagraphStyle()
            p.lineSpacing = ZenTheme.editorLineSpacing
            p.paragraphSpacing = ZenTheme.editorParagraphSpacing
            return p
        }()
        return [
            .font: ZenTheme.editorFont,
            .foregroundColor: ZenTheme.nsInk,
            .paragraphStyle: ps
        ]
    }

    // MARK: — Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isEditing = true
            parent.text = RichTextEditor.rtfString(from: textView)
            isEditing = false
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }
    }
}
