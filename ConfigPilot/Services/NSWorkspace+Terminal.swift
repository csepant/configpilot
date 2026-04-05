import AppKit

extension NSWorkspace {
    /// Open the user's preferred terminal app at a given directory.
    func openTerminal(at directoryURL: URL) {
        let path = directoryURL.path

        // Detect which terminal is installed, in preference order
        let terminalBundleIDs = [
            "com.mitchellh.ghostty",
            "com.googlecode.iterm2",
            "io.alacritty",
            "net.kovidgoyal.kitty",
            "com.apple.Terminal"
        ]

        let bundleID = terminalBundleIDs.first { urlForApplication(withBundleIdentifier: $0) != nil }
            ?? "com.apple.Terminal"

        switch bundleID {
        case "com.mitchellh.ghostty":
            runAppleScript("""
                tell application "Ghostty"
                    activate
                end tell
                delay 0.3
                tell application "System Events"
                    tell process "Ghostty"
                        keystroke "n" using command down
                        delay 0.3
                        keystroke "cd \(escapedForAppleScript(path))"
                        key code 36
                    end tell
                end tell
                """)

        case "com.googlecode.iterm2":
            runAppleScript("""
                tell application "iTerm"
                    activate
                    create window with default profile command "cd \(escapedForAppleScript(path)) && exec $SHELL"
                end tell
                """)

        case "io.alacritty":
            // Alacritty supports --working-directory flag
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-na", "Alacritty", "--args", "--working-directory", path]
            try? process.run()

        case "net.kovidgoyal.kitty":
            // Kitty supports --directory flag
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-na", "kitty", "--args", "--directory", path]
            try? process.run()

        default:
            // Terminal.app
            runAppleScript("""
                tell application "Terminal"
                    activate
                    do script "cd \(escapedForAppleScript(path))"
                end tell
                """)
        }
    }

    private func runAppleScript(_ source: String) {
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
        }
    }

    private func escapedForAppleScript(_ string: String) -> String {
        string.replacingOccurrences(of: "\\", with: "\\\\")
              .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
