import Testing
@testable import Lightning

@Suite struct AppScannerTests {
    let scanner = AppScanner()

    @Test func tokenizeSimpleName() {
        let tokens = scanner.tokenize("Safari")
        #expect(tokens.contains("safari"))
    }

    @Test func tokenizeMultiWord() {
        let tokens = scanner.tokenize("Visual Studio Code")
        #expect(tokens.contains("visual"))
        #expect(tokens.contains("studio"))
        #expect(tokens.contains("code"))
    }

    @Test func tokenizeCamelCase() {
        let tokens = scanner.tokenize("WebStorm")
        #expect(tokens.contains("web"))
        #expect(tokens.contains("storm"))
    }

    @Test func tokenizeWithHyphen() {
        let tokens = scanner.tokenize("Hex-Editor")
        #expect(tokens.contains("hex"))
        #expect(tokens.contains("editor"))
    }

    @Test func tokenizeWithDot() {
        let tokens = scanner.tokenize("com.app.name")
        #expect(tokens.contains("com"))
        #expect(tokens.contains("app"))
        #expect(tokens.contains("name"))
    }

    @Test func tokenizeIncludesFullName() {
        let tokens = scanner.tokenize("Visual Studio Code")
        #expect(tokens.first == "visual studio code")
    }

    @Test func scanFindsSystemApps() {
        // Integration test: should find at least some apps
        let entries = scanner.scan()
        #expect(entries.count > 0)
    }
}
