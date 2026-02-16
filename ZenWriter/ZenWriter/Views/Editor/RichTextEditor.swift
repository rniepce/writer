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

        // — Default typing attributes (for new text)
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
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Only update if text changed externally (chapter switch)
        if !context.coordinator.isEditing {
            let currentRtf = rtfString(from: textView)
            if currentRtf != text {
                loadContent(into: textView)
            }
        }
    }

    // MARK: — RTF Serialization

    /// Load RTF string into the text view. Falls back to plain text.
    private func loadContent(into textView: NSTextView) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = ZenTheme.editorLineSpacing
        paragraphStyle.paragraphSpacing = ZenTheme.editorParagraphSpacing

        if text.hasPrefix("{\\rtf"), let data = text.data(using: .utf8) {
            // Load as RTF
            if let attrStr = NSAttributedString(rtf: data, documentAttributes: nil) {
                textView.textStorage?.setAttributedString(attrStr)
                // Re-apply paragraph style and ink color throughout
                let range = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
                textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                textView.textStorage?.addAttribute(.foregroundColor, value: ZenTheme.nsInk, range: range)
                return
            }
        }

        // Load as plain text
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

    /// Instance method for convenience
    private func rtfString(from textView: NSTextView) -> String {
        Self.rtfString(from: textView)
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
        weak var textView: NSTextView?

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

        // MARK: — Formatting Actions

        func toggleBold() {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            guard range.length > 0 else {
                // Toggle bold in typing attributes
                toggleTraitInTypingAttributes(.boldFontMask, textView: textView)
                return
            }
            textView.textStorage?.enumerateAttribute(.font, in: range) { value, subRange, _ in
                guard let font = value as? NSFont else { return }
                let newFont: NSFont
                if font.fontDescriptor.symbolicTraits.contains(.bold) {
                    newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                }
                textView.textStorage?.addAttribute(.font, value: newFont, range: subRange)
            }
            textView.didChangeText()
        }

        func toggleItalic() {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            guard range.length > 0 else {
                toggleTraitInTypingAttributes(.italicFontMask, textView: textView)
                return
            }
            textView.textStorage?.enumerateAttribute(.font, in: range) { value, subRange, _ in
                guard let font = value as? NSFont else { return }
                let newFont: NSFont
                if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                }
                textView.textStorage?.addAttribute(.font, value: newFont, range: subRange)
            }
            textView.didChangeText()
        }

        func applyHeading() {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            let headingFont = NSFont.systemFont(ofSize: 24, weight: .bold)
            let bodyFont = ZenTheme.editorFont

            // Check if already heading
            var isHeading = false
            if range.length > 0 {
                if let font = textView.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                    isHeading = font.pointSize >= 22
                }
            }

            let targetFont = isHeading ? bodyFont : headingFont
            let applyRange = range.length > 0 ? range : expandToLine(from: range.location, in: textView)

            textView.textStorage?.addAttribute(.font, value: targetFont, range: applyRange)
            textView.textStorage?.addAttribute(.foregroundColor, value: ZenTheme.nsInk, range: applyRange)
            textView.didChangeText()
        }

        private func expandToLine(from location: Int, in textView: NSTextView) -> NSRange {
            let string = textView.string as NSString
            return string.lineRange(for: NSRange(location: location, length: 0))
        }

        private func toggleTraitInTypingAttributes(_ trait: NSFontTraitMask, textView: NSTextView) {
            var attrs = textView.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let hasTrait = font.fontDescriptor.symbolicTraits.contains(
                    trait == .boldFontMask ? .bold : .italic
                )
                let newFont: NSFont
                if hasTrait {
                    newFont = NSFontManager.shared.convert(font, toNotHaveTrait: trait)
                } else {
                    newFont = NSFontManager.shared.convert(font, toHaveTrait: trait)
                }
                attrs[.font] = newFont
                textView.typingAttributes = attrs
            }
        }
    }
}
