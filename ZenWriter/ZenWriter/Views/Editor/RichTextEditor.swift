import SwiftUI
import AppKit

/// A native macOS rich text editor wrapping NSTextView.
/// Provides a clean, distraction-free writing experience with serif typography.
struct RichTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Text view configuration
        textView.isRichText = false   // Plain text for v1
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.usesFindPanel = true
        textView.usesFindBar = true

        // Typography — warm, book-like feel
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 16

        textView.defaultParagraphStyle = paragraphStyle
        textView.font = NSFont(name: "Georgia", size: 17) ?? NSFont.systemFont(ofSize: 17)
        textView.textColor = NSColor.textColor

        // Inset for breathing room
        textView.textContainerInset = NSSize(width: 80, height: 60)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 700,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Background
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true

        // Set initial content
        textView.string = text

        // Delegate
        textView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Only update if the text actually changed externally (chapter switch)
        if textView.string != text && !context.coordinator.isEditing {
            textView.string = text
        }
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
            parent.text = textView.string
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
