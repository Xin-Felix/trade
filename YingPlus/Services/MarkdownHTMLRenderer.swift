import Foundation

/// 将 Markdown 文本转换为可展示的自适应 HTML 页面。
///
/// 仅支持复盘报告常用的基础语法：标题、段落、无序/有序列表、加粗、斜体、
/// 行内代码、代码块、分隔线、链接。
enum MarkdownHTMLRenderer {
    static func render(_ markdown: String) -> String {
        let body = markdownToHTML(markdown)
        return wrapHTML(body)
    }

    // MARK: - 行内格式

    private static func inlineFormat(_ text: String) -> String {
        var result = escape(text)

        // 行内代码 `code`
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<code>$1</code>",
            options: .regularExpression
        )

        // 加粗 **text** 或 __text__
        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "__(.+?)__",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        // 斜体 *text* 或 _text_
        result = result.replacingOccurrences(
            of: "\\*(.+?)\\*",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "_(.+?)_",
            with: "<em>$1</em>",
            options: .regularExpression
        )

        // 链接 [text](url)
        result = result.replacingOccurrences(
            of: "\\[(\\]?)\\]?\\(([^)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )

        return result
    }

    // MARK: - 块级转换

    private static func markdownToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var result: [String] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            // 代码块 ```
            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                index += 1
                while index < lines.count && !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                index += 1 // 跳过结束 ```
                let code = escape(codeLines.joined(separator: "\n"))
                let langAttr = language.isEmpty ? "" : " class=\"language-\(language)\""
                result.append("<pre><code\(langAttr)>\(code)</code></pre>")
                continue
            }

            // 分隔线
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                result.append("<hr/>")
                index += 1
                continue
            }

            // 标题
            if let heading = parseHeading(trimmed) {
                result.append(heading)
                index += 1
                continue
            }

            // 无序列表
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while index < lines.count {
                    let itemLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if itemLine.isEmpty { break }
                    if itemLine.hasPrefix("- ") {
                        items.append("<li>\(inlineFormat(String(itemLine.dropFirst(2))))</li>")
                        index += 1
                    } else if itemLine.hasPrefix("* ") {
                        items.append("<li>\(inlineFormat(String(itemLine.dropFirst(2))))</li>")
                        index += 1
                    } else {
                        break
                    }
                }
                if !items.isEmpty {
                    result.append("<ul>\(items.joined())</ul>")
                }
                continue
            }

            // 有序列表
            if trimmed.range(of: "^\\d+\\. ", options: .regularExpression) != nil {
                var items: [String] = []
                while index < lines.count {
                    let itemLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if itemLine.isEmpty { break }
                    if let range = itemLine.range(of: "^\\d+\\. ", options: .regularExpression) {
                        let content = String(itemLine[range.upperBound...])
                        items.append("<li>\(inlineFormat(content))</li>")
                        index += 1
                    } else {
                        break
                    }
                }
                if !items.isEmpty {
                    result.append("<ol>\(items.joined())</ol>")
                }
                continue
            }

            // 普通段落
            result.append("<p>\(inlineFormat(line))</p>")
            index += 1
        }

        return result.joined()
    }

    private static func parseHeading(_ line: String) -> String? {
        for level in (1...6).reversed() {
            let prefix = String(repeating: "#", count: level) + " "
            if line.hasPrefix(prefix) {
                let content = String(line.dropFirst(prefix.count))
                return "<h\(level)>\(inlineFormat(content))</h\(level)>"
            }
        }
        return nil
    }

    private static func escape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - HTML 包装

    private static func wrapHTML(_ body: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            :root {
                color-scheme: light dark;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                font-size: 16px;
                line-height: 1.7;
                color: #000000;
                background-color: #FFFFFF;
                padding: 16px;
                margin: 0;
                word-wrap: break-word;
            }
            @media (prefers-color-scheme: dark) {
                body {
                    color: #FFFFFF;
                    background-color: #000000;
                }
                a { color: #5AC8FA; }
                code, pre {
                    background-color: #1C1C1E;
                    color: #FFFFFF;
                }
            }
            h1, h2, h3, h4, h5, h6 {
                margin-top: 24px;
                margin-bottom: 12px;
                font-weight: 600;
                line-height: 1.3;
            }
            h1 { font-size: 22px; }
            h2 { font-size: 20px; }
            h3 { font-size: 18px; }
            p { margin: 0 0 14px 0; }
            ul, ol {
                margin: 0 0 14px 0;
                padding-left: 22px;
            }
            li { margin-bottom: 6px; }
            a { color: #007AFF; text-decoration: none; }
            code {
                font-family: "SF Mono", Menlo, Consolas, monospace;
                background-color: rgba(120, 120, 128, 0.16);
                padding: 2px 5px;
                border-radius: 4px;
                font-size: 14px;
            }
            pre {
                font-family: "SF Mono", Menlo, Consolas, monospace;
                background-color: rgba(120, 120, 128, 0.12);
                padding: 12px;
                border-radius: 8px;
                overflow-x: auto;
                margin: 0 0 14px 0;
            }
            pre code {
                background-color: transparent;
                padding: 0;
            }
            hr {
                border: none;
                border-top: 1px solid rgba(120, 120, 128, 0.3);
                margin: 20px 0;
            }
            strong { font-weight: 600; }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
