import SwiftUI
import WebKit

/// H5 内容展示页
struct H5PageView: View {
    let slug: String
    let defaultTitle: String

    @State private var page: H5PageData?
    @State private var isLoading = true
    @State private var loadError: Error?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if let error = loadError {
                errorState(error)
            } else if let page = page {
                H5WebView(htmlString: wrapHTML(page.renderedHTML))
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle(page?.title ?? defaultTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadPage() }
    }

    private func errorState(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(YPColor.warning.opacity(0.8))
            Text("页面加载失败")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func loadPage() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            page = try await H5PageService.fetchH5Page(slug: slug)
        } catch {
            loadError = error
            print("[H5Page] \(slug) 加载失败: \(error.localizedDescription)")
        }
    }

    private func wrapHTML(_ bodyHTML: String) -> String {
        """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    padding: 16px;
                    margin: 0;
                    color: \(colorCSS(.label));
                    background-color: \(colorCSS(.systemBackground));
                }
                h1, h2, h3, h4, h5, h6 { color: \(colorCSS(.label)); margin-top: 1.2em; margin-bottom: 0.6em; }
                p { margin: 0.8em 0; }
                a { color: \(colorCSS(.systemBlue)); }
                img { max-width: 100%; height: auto; border-radius: 8px; }
                pre, code { background-color: \(colorCSS(.secondarySystemBackground)); border-radius: 4px; }
                blockquote { border-left: 4px solid \(colorCSS(.separator)); padding-left: 12px; color: \(colorCSS(.secondaryLabel)); }
            </style>
        </head>
        <body>
            \(bodyHTML)
        </body>
        </html>
        """
    }

    private func colorCSS(_ color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "rgba(%.0f, %.0f, %.0f, %.2f)", r * 255, g * 255, b * 255, a)
    }
}

struct H5WebView: UIViewRepresentable {
    let htmlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.showsVerticalScrollIndicator = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}

#Preview {
    NavigationStack {
        H5PageView(slug: "help-feedback", defaultTitle: "帮助与反馈")
    }
}
