#if canImport(SwiftUI) && canImport(PDFKit) && canImport(AppKit)
import SwiftUI

@main
struct TicTieMacApp: App {
    var body: some Scene {
        WindowGroup("TicTie Mac") {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Link("About TicTie Mac", destination: URL(string: "https://github.com/ManTreeJoe/not-tictie-calc-mac")!)
            }
        }
    }
}

#else

// On non-Apple platforms (e.g. Linux CI) there is no SwiftUI/PDFKit, so the
// executable degrades to a small message. `TicTieCore` still builds and tests
// run, which is what CI needs.
@main
struct TicTieMacApp {
    static func main() {
        print("TicTie Mac is a macOS (SwiftUI + PDFKit) application.")
        print("Build and run it on macOS 13+ with: swift run TicTieMac")
    }
}

#endif
