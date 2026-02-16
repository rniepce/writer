import SwiftUI
import AppKit

/// ZenWriter Design System — Warm, distraction-free writing aesthetic
enum ZenTheme {

    // MARK: — Colors

    /// Warm parchment background for the editor
    static let parchment = Color(red: 0.98, green: 0.96, blue: 0.93)
    /// Sidebar uses system sidebar background for proper macOS integration
    static let sidebarBg = Color(nsColor: .controlBackgroundColor)
    /// Warm ink color — not pure black
    static let ink = Color(red: 0.18, green: 0.16, blue: 0.14)
    /// Muted secondary text
    static let inkLight = Color(red: 0.45, green: 0.42, blue: 0.38)
    /// Subtle border/divider
    static let divider = Color(nsColor: .separatorColor)
    /// Accent — warm amber
    static let amber = Color(red: 0.76, green: 0.55, blue: 0.20)
    /// Light amber for selection backgrounds
    static let amberLight = Color(red: 0.76, green: 0.55, blue: 0.20).opacity(0.12)
    /// Success green for save indicator
    static let saved = Color(red: 0.40, green: 0.62, blue: 0.45)

    // MARK: — NSColors (for NSTextView)

    static var nsParchment: NSColor {
        NSColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
    }

    static var nsInk: NSColor {
        NSColor(red: 0.18, green: 0.16, blue: 0.14, alpha: 1.0)
    }

    // MARK: — Typography

    static let editorFont = NSFont(name: "Georgia", size: 18) ?? NSFont.systemFont(ofSize: 18)
    static let editorLineSpacing: CGFloat = 10
    static let editorParagraphSpacing: CGFloat = 18

    // MARK: — Dimensions

    static let editorMaxWidth: CGFloat = 680
    static let editorHorizontalInset: CGFloat = 100
    static let editorVerticalInset: CGFloat = 80
    static let sidebarMinWidth: CGFloat = 240
    static let sidebarIdealWidth: CGFloat = 280
    static let sidebarMaxWidth: CGFloat = 340
}

// MARK: — Feather Icon

/// Custom feather/quill icon drawn with SwiftUI paths
struct FeatherIcon: View {
    var size: CGFloat = 48
    var color: Color = ZenTheme.amber

    var body: some View {
        Image(systemName: "leaf")
            .font(.system(size: size, weight: .ultraLight))
            .foregroundStyle(color)
            .rotationEffect(.degrees(-45))
    }
}
