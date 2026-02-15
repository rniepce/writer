import SwiftUI
import SwiftData

@main
struct ZenWriterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, Chapter.self, ReferenceDoc.self])
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
    }
}
