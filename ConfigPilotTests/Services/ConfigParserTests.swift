import XCTest
@testable import ConfigPilot

final class ConfigParserTests: XCTestCase {
    let parser = ConfigParser()

    // MARK: - INI Parsing (Git Config)

    func testParseGitConfig() throws {
        let url = Bundle(for: type(of: self)).url(forResource: "sample-gitconfig", withExtension: nil, subdirectory: "Fixtures")
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Fixtures/sample-gitconfig")

        let values = try parser.parse(file: url, format: .ini)

        XCTAssertFalse(values.isEmpty, "Should parse values from git config")

        // Check specific values
        let userNameValue = values.first { $0.key == "user.name" }
        XCTAssertNotNil(userNameValue)
        XCTAssertEqual(userNameValue?.rawValue, "Test User")

        let userEmailValue = values.first { $0.key == "user.email" }
        XCTAssertNotNil(userEmailValue)
        XCTAssertEqual(userEmailValue?.rawValue, "test@example.com")

        let coreEditorValue = values.first { $0.key == "core.editor" }
        XCTAssertNotNil(coreEditorValue)
        XCTAssertEqual(coreEditorValue?.rawValue, "vim")

        let coreAutocrlfValue = values.first { $0.key == "core.autocrlf" }
        XCTAssertNotNil(coreAutocrlfValue)
        XCTAssertEqual(coreAutocrlfValue?.rawValue, "input")

        let pushDefaultValue = values.first { $0.key == "push.default" }
        XCTAssertNotNil(pushDefaultValue)
        XCTAssertEqual(pushDefaultValue?.rawValue, "current")

        let pullRebaseValue = values.first { $0.key == "pull.rebase" }
        XCTAssertNotNil(pullRebaseValue)
        XCTAssertEqual(pullRebaseValue?.rawValue, "true")
    }

    func testParseGitConfigLineNumbers() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/sample-gitconfig")

        let values = try parser.parse(file: url, format: .ini)

        // Line numbers should be set
        for value in values {
            XCTAssertNotNil(value.lineNumber, "Line number should be set for \(value.key)")
            XCTAssertGreaterThan(value.lineNumber ?? 0, 0)
        }
    }

    // MARK: - Lua Parsing (Neovim)

    func testParseLuaConfig() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/sample-init.lua")

        let values = try parser.parse(file: url, format: .lua)

        XCTAssertFalse(values.isEmpty, "Should parse values from Lua config")

        let numberValue = values.first { $0.key == "opt.number" }
        XCTAssertNotNil(numberValue)
        XCTAssertEqual(numberValue?.rawValue, "true")

        let tabstopValue = values.first { $0.key == "opt.tabstop" }
        XCTAssertNotNil(tabstopValue)
        XCTAssertEqual(tabstopValue?.rawValue, "4")

        let mouseValue = values.first { $0.key == "opt.mouse" }
        XCTAssertNotNil(mouseValue)
        XCTAssertEqual(mouseValue?.rawValue, "a")

        let mapleaderValue = values.first { $0.key == "g.mapleader" }
        XCTAssertNotNil(mapleaderValue)
        XCTAssertEqual(mapleaderValue?.rawValue, " ")
    }

    // MARK: - INI Parsing (tmux)

    func testParseTmuxConfig() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/sample-tmux.conf")

        let values = try parser.parse(file: url, format: .ini)

        XCTAssertFalse(values.isEmpty, "Should parse values from tmux config")

        let prefixValue = values.first { $0.key == "prefix" }
        XCTAssertNotNil(prefixValue)
        XCTAssertEqual(prefixValue?.rawValue, "C-a")

        let defaultTermValue = values.first { $0.key == "default-terminal" }
        XCTAssertNotNil(defaultTermValue)
        XCTAssertEqual(defaultTermValue?.rawValue, "\"tmux-256color\"")

        let mouseValue = values.first { $0.key == "mouse" }
        XCTAssertNotNil(mouseValue)
        XCTAssertEqual(mouseValue?.rawValue, "on")
    }

    // MARK: - Key-Value Parsing (Ghostty)

    func testParseKeyValueFormat() throws {
        let content = """
        # Ghostty config
        font-family = JetBrains Mono
        font-size = 14
        theme = catppuccin-mocha
        window-padding-x = 10
        window-padding-y = 10
        background-opacity = 0.95
        """

        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test-ghostty-config")
        try content.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let values = try parser.parse(file: tmpFile, format: .keyvalue)

        XCTAssertEqual(values.count, 6)

        let fontFamily = values.first { $0.key == "font-family" }
        XCTAssertEqual(fontFamily?.rawValue, "JetBrains Mono")

        let fontSize = values.first { $0.key == "font-size" }
        XCTAssertEqual(fontSize?.rawValue, "14")
    }

    // MARK: - TOML Parsing

    func testParseTOMLFormat() throws {
        let content = """
        [window]
        opacity = 0.95
        decorations = "Full"

        [font]
        size = 13.0

        [font.normal]
        family = "JetBrains Mono"
        """

        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test-alacritty.toml")
        try content.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let values = try parser.parse(file: tmpFile, format: .toml)

        XCTAssertFalse(values.isEmpty)

        let opacity = values.first { $0.key == "window.opacity" }
        XCTAssertEqual(opacity?.rawValue, "0.95")

        let fontFamily = values.first { $0.key == "font.normal.family" }
        XCTAssertEqual(fontFamily?.rawValue, "JetBrains Mono")
    }

    // MARK: - Zshrc Parsing

    func testParseZshrc() throws {
        let content = """
        # Zsh config
        export EDITOR="nvim"
        export VISUAL="nvim"
        export PAGER="less"

        setopt AUTO_CD
        setopt EXTENDED_GLOB
        setopt HIST_IGNORE_DUPS
        unsetopt BEEP

        HISTSIZE=10000
        SAVEHIST=10000

        plugins=(git docker kubectl)
        """

        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test-zshrc")
        try content.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let values = try parser.parse(file: tmpFile, format: .zshrc)

        let editor = values.first { $0.key == "export.EDITOR" }
        XCTAssertEqual(editor?.rawValue, "nvim")

        let autoCD = values.first { $0.key == "setopt.AUTO_CD" }
        XCTAssertEqual(autoCD?.rawValue, "true")

        let beep = values.first { $0.key == "setopt.BEEP" }
        XCTAssertEqual(beep?.rawValue, "false")

        let histSize = values.first { $0.key == "var.HISTSIZE" }
        XCTAssertEqual(histSize?.rawValue, "10000")

        let plugins = values.first { $0.key == "plugins" }
        XCTAssertEqual(plugins?.rawValue, "git docker kubectl")
    }

    // MARK: - Edge Cases

    func testParseEmptyFile() throws {
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test-empty")
        try "".write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let values = try parser.parse(file: tmpFile, format: .ini)
        XCTAssertTrue(values.isEmpty)
    }

    func testParseCommentsOnlyFile() throws {
        let content = """
        # This is a comment
        ; This is also a comment
        # Another comment
        """

        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test-comments")
        try content.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let values = try parser.parse(file: tmpFile, format: .ini)
        XCTAssertTrue(values.isEmpty)
    }
}
