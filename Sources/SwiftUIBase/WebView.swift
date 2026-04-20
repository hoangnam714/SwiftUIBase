import SwiftUI
import WebKit

public struct WebView: View {
    public let url: URL
    @Binding public var isLoading: Bool
    @Binding public var progress: Double

    public init(url: URL, isLoading: Binding<Bool>, progress: Binding<Double>) {
        self.url = url
        self._isLoading = isLoading
        self._progress = progress
    }

    public var body: some View {
        Representable(url: url, isLoading: $isLoading, progress: $progress)
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        private var progressObservation: NSKeyValueObservation?
        @Binding private var isLoading: Bool
        @Binding private var progress: Double

        init(isLoading: Binding<Bool>, progress: Binding<Double>) {
            self._isLoading = isLoading
            self._progress = progress
        }

        func attach(to webView: WKWebView) {
            progressObservation?.invalidate()
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.progress = view.estimatedProgress
                }
            }
        }

        func detach(from webView: WKWebView) {
            progressObservation?.invalidate()
            progressObservation = nil
            webView.navigationDelegate = nil
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = true
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.progress = 1.0
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

#if canImport(UIKit)
private extension WebView {
    struct Representable: UIViewRepresentable {
        let url: URL
        @Binding var isLoading: Bool
        @Binding var progress: Double

        func makeCoordinator() -> WebView.Coordinator {
            WebView.Coordinator(isLoading: $isLoading, progress: $progress)
        }

        func makeUIView(context: Context) -> WKWebView {
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = context.coordinator
            webView.allowsBackForwardNavigationGestures = true

            context.coordinator.attach(to: webView)
            webView.load(URLRequest(url: url))
            return webView
        }

        func updateUIView(_ webView: WKWebView, context: Context) {
            if webView.url != url {
                webView.load(URLRequest(url: url))
            }
        }

        static func dismantleUIView(_ uiView: WKWebView, coordinator: WebView.Coordinator) {
            coordinator.detach(from: uiView)
        }
    }
}
#elseif canImport(AppKit)
private extension WebView {
    struct Representable: NSViewRepresentable {
        let url: URL
        @Binding var isLoading: Bool
        @Binding var progress: Double

        func makeCoordinator() -> WebView.Coordinator {
            WebView.Coordinator(isLoading: $isLoading, progress: $progress)
        }

        func makeNSView(context: Context) -> WKWebView {
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = context.coordinator
            webView.allowsBackForwardNavigationGestures = true

            context.coordinator.attach(to: webView)
            webView.load(URLRequest(url: url))
            return webView
        }

        func updateNSView(_ webView: WKWebView, context: Context) {
            if webView.url != url {
                webView.load(URLRequest(url: url))
            }
        }

        static func dismantleNSView(_ nsView: WKWebView, coordinator: WebView.Coordinator) {
            coordinator.detach(from: nsView)
        }
    }
}
#endif
