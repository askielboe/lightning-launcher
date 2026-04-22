import Foundation

/// Evaluates simple arithmetic expressions typed into the search box.
///
/// Supports `+`, `-`, `*`, `/`, `^` (power), `sqrt`, parentheses,
/// and decimal numbers. Uses a recursive descent parser with correct
/// operator precedence. Cost is O(n) in the length of the query string
/// and runs once per query change — not on the per-entry hot path.
enum ArithmeticEvaluator {
    /// Attempts to evaluate the query as an arithmetic expression.
    ///
    /// Returns the formatted result string, or `nil` if the query
    /// is not a valid expression or is just a bare number.
    static func evaluate(_ input: String) -> String? {
        // Quick bail: must contain at least one digit
        guard input.unicodeScalars.contains(where: { $0.properties.numericType != nil }) else {
            return nil
        }

        var parser = Parser(Array(input))
        guard let value = parser.parseExpression(),
              parser.isAtEnd,
              parser.hadOperator,
              value.isFinite
        else { return nil }

        return formatResult(value)
    }

    private static func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0, abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.12g", value)
    }
}

// MARK: - Recursive Descent Parser

/// Grammar (highest precedence at the bottom):
/// ```
/// expr    → term (('+' | '-') term)*
/// term    → power (('*' | '/') power)*
/// power   → unary ('^' power)?          // right-associative
/// unary   → "sqrt" unary | '-' unary | primary
/// primary → NUMBER | '(' expr ')'
/// ```
private struct Parser {
    private let chars: [Character]
    private var pos: Int = 0
    private(set) var hadOperator = false

    init(_ chars: [Character]) {
        self.chars = chars
    }

    var isAtEnd: Bool {
        var i = pos
        while i < chars.count, chars[i] == " " {
            i += 1
        }
        return i >= chars.count
    }

    // MARK: - Grammar rules

    mutating func parseExpression() -> Double? {
        guard var left = parseTerm() else { return nil }
        while let op = peek(), op == "+" || op == "-" {
            hadOperator = true
            advance()
            guard let right = parseTerm() else { return nil }
            left = op == "+" ? left + right : left - right
        }
        return left
    }

    private mutating func parseTerm() -> Double? {
        guard var left = parsePower() else { return nil }
        while let op = peek(), op == "*" || op == "/" {
            hadOperator = true
            advance()
            guard let right = parsePower() else { return nil }
            left = op == "*" ? left * right : left / right
        }
        return left
    }

    private mutating func parsePower() -> Double? {
        guard let base = parseUnary() else { return nil }
        if peek() == "^" {
            hadOperator = true
            advance()
            guard let exp = parsePower() else { return nil }
            return pow(base, exp)
        }
        return base
    }

    private mutating func parseUnary() -> Double? {
        skipSpaces()

        // sqrt
        if pos + 4 <= chars.count,
           chars[pos] == "s", chars[pos + 1] == "q",
           chars[pos + 2] == "r", chars[pos + 3] == "t"
        {
            hadOperator = true
            pos += 4
            guard let operand = parseUnary() else { return nil }
            return sqrt(operand)
        }

        // Unary minus
        if pos < chars.count, chars[pos] == "-" {
            pos += 1
            guard let operand = parseUnary() else { return nil }
            return -operand
        }

        return parsePrimary()
    }

    private mutating func parsePrimary() -> Double? {
        skipSpaces()

        if pos < chars.count, chars[pos] == "(" {
            advance()
            guard let value = parseExpression() else { return nil }
            guard peek() == ")" else { return nil }
            advance()
            return value
        }

        return parseNumber()
    }

    private mutating func parseNumber() -> Double? {
        skipSpaces()
        let start = pos

        while pos < chars.count, chars[pos].isNumber || chars[pos] == "." {
            pos += 1
        }

        guard pos > start else { return nil }
        return Double(String(chars[start ..< pos]))
    }

    // MARK: - Helpers

    private mutating func skipSpaces() {
        while pos < chars.count, chars[pos] == " " {
            pos += 1
        }
    }

    private mutating func peek() -> Character? {
        skipSpaces()
        return pos < chars.count ? chars[pos] : nil
    }

    private mutating func advance() {
        pos += 1
    }
}
