import SwiftUI
import AppKit

/// A native macOS text editor with warm, book-like typography.
/// Wraps NSTextView for native performance and feel.
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

        // Style the scroller to be minimal
        scrollView.scrollerStyle = .overlay

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // — Core Config
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false  // Clean look — no red squiggles
        textView.usesFindPanel = true
        textView.usesFindBar = true

        // — Typography: warm, book-like
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = ZenTheme.editorLineSpacing
        paragraphStyle.paragraphSpacing = ZenTheme.editorParagraphSpacing
        paragraphStyle.alignment = .natural

        textView.defaultParagraphStyle = paragraphStyle
        textView.font = ZenTheme.editorFont
        textView.textColor = ZenTheme.nsInk

        // — Generous margins for reading comfort
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

        // — Insertion point color — warm amber
        textView.insertionPointColor = NSColor(
            red: 0.76, green: 0.55, blue: 0.20, alpha: 1.0
        )

        // — Selection color — light amber
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(
                red: 0.76, green: 0.55, blue: 0.20, alpha: 0.15
            ),
            .foregroundColor: ZenTheme.nsInk
        ]

        // Set initial content
        textView.string = text
        textView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Only update if text changed externally (chapter switch)
        if textView.string != text && !context.coordinator.isEditing {
            let cursorPos = textView.selectedRange().location
            textView.string = text
            // Re-apply typography after content change
            let range = NSRange(location: 0, length: textView.string.count)
            textView.setFont(ZenTheme.editorFont, range: range)
            textView.textColor = ZenTheme.nsInk
            if let ps = textView.defaultParagraphStyle {
                textView.textStorage?.addAttribute(.paragraphStyle, value: ps, range: range)
            }
            // Restore cursor
            let safeCursor = min(cursorPos, textView.string.count)
            textView.setSelectedRange(NSRange(location: safeCursor, length: 0))
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
