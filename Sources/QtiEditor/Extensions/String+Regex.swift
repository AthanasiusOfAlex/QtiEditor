//
//  String+Regex.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import Foundation

extension String {
    /// Performs a regex replacement using $n syntax, with support for escaping.
    /// - `pattern`: The regex to find (e.g. `(\w+)`).
    /// - `template`: The replacement string. Use `$1` for groups, `\$1` for literal "$1".
    func replacingWithTemplate(matching pattern: String, with template: String) throws -> String {

        let searchRegex = try Regex(pattern)

        // PARSER LOGIC (Simplified):
        // Option 1: \\$     -> Matches a literal backslash followed by $. (Escaped $)
        // Option 2: $(\d+)  -> Matches a $ and digits. (Real Token)
        let templateParser = /\\\$|\$(\d+)/

        return self.replacing(searchRegex) { match in

            // We are now building the replacement string segment
            return template.replacing(templateParser) { tokenMatch in

                // CHECK FOR REAL TOKEN (e.g. "$1")
                // If the capture group (output.1) exists, it's a $N token.
                if let validDigitStr = tokenMatch.output.1,
                   let index = Int(validDigitStr) {

                    // Handle $0 (Whole Match)
                    if index == 0 { return String(match.0) }

                    // Handle $1...$n (Existing Groups)
                    // Note: accessing AnyRegexOutput via subscript
                    if index < match.output.count,
                       let captured = match.output[index].substring {
                        return String(captured)
                    }

                    // Fallback for invalid groups
                    return ""
                }

                // CHECK FOR ESCAPED TOKEN (e.g. "\$")
                // If we are here, the regex matched `\$` (Option 1).
                // We return a literal "$" effectively stripping the backslash.
                return "$"
            }
        }
    }
}
