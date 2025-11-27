import XCTest
@testable import QtiEditor

final class RegexTests: XCTestCase {

    struct TestCase {
        let name: String
        let input: String
        let pattern: String
        let template: String
        let expected: String
    }

    func testRegexReplacements() {
        let tests: [TestCase] = [
            // --- BASIC FUNCTIONALITY ---
            TestCase(
                name: "Basic Swap",
                input: "John Doe",
                pattern: #"(\w+) (\w+)"#,
                template: "$2, $1",
                expected: "Doe, John"
            ),
            TestCase(
                name: "Whole Match ($0)",
                input: "Price 100",
                pattern: #"\d+"#,
                template: "[$0]",
                expected: "Price [100]"
            ),

            // --- ESCAPING ($1 vs \$1) ---
            TestCase(
                name: "Simple Escape",
                input: "Item 100",
                pattern: #"(\d+)"#,
                template: "Price: \\$1", // In memory: "Price: \$1"
                expected: "Item Price: $1"
            ),
            TestCase(
                name: "Mixed Real and Escaped",
                input: "100",
                pattern: #"(\d+)"#,
                template: "Value: $$1 (Literal: \\$1)", // In memory: "Value: $$1 (Literal: \$1)"
                expected: "Value: $100 (Literal: $1)"
            ),

            // --- EDGE CASES ---
            TestCase(
                name: "Non-Existent Group (High Index)",
                input: "Hello",
                pattern: #"(\w+)"#,
                template: "Group 1: $1, Group 99: $99",
                expected: "Group 1: Hello, Group 99: "
            ),
            TestCase(
                name: "Repeated Groups",
                input: "Na",
                pattern: #"(Na)"#,
                template: "$1$1$1 Batman",
                expected: "NaNaNa Batman"
            ),
            TestCase(
                name: "Adjacent Escapes",
                input: "A",
                pattern: #"(A)"#,
                template: "\\$1$1", // Should be literal "$1" followed by content "A"
                expected: "$1A"
            ),
            TestCase(
                name: "Preserve Unrelated Text",
                input: "foo-bar",
                pattern: #"-(\w+)"#, // Matches "-bar", captures "bar"
                template: " converted to $1",
                expected: "foo converted to bar"
            ),

            // --- COMPLEX / FUZZY ---
            TestCase(
                name: "Complex Currency Format",
                input: "price=500",
                pattern: #"(\w+)=(\d+)"#,
                template: "$1 is \\$$2.00",
                expected: "price is $500.00"
            ),
            TestCase(
                name: "Empty Capture",
                input: "startend",
                pattern: #"start(.*)end"#,
                template: "[$1]",
                expected: "[]"
            ),

            // --- ADVANCED FEATURES (Anchors, Lookarounds, Non-Capturing) ---
            TestCase(
                name: "Anchors (^ and $)",
                input: "start middle start",
                pattern: #"^start"#,
                template: "BEGIN",
                expected: "BEGIN middle start"
            ),
            TestCase(
                name: "Positive Lookahead (?=)",
                input: "100USD 200EUR",
                pattern: #"\d+(?=USD)"#,
                template: "$$0",
                expected: "$100USD 200EUR"
            ),
            TestCase(
                name: "Non-Capturing Group (?:)",
                input: "Group: 123",
                pattern: #"(?:Group): (\d+)"#,
                template: "ID: $1",
                expected: "ID: 123"
            ),
            TestCase(
                name: "Lookbehind (?<=)",
                input: "foobar bazbar",
                pattern: #"(?<=foo)bar"#,
                template: "BAZ",
                expected: "fooBAZ bazbar"
            )
        ]

        for test in tests {
            do {
                let result = try test.input.replacingWithTemplate(
                    matching: test.pattern,
                    with: test.template
                )
                XCTAssertEqual(result, test.expected, "Failed test: \(test.name)")
            } catch {
                XCTFail("Error in test \(test.name): \(error)")
            }
        }
    }
}
