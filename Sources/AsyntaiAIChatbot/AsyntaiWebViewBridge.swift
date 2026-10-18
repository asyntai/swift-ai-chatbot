#if canImport(WebKit)
import Foundation
import WebKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Makes the `WKWebView` for the chat and connects it to the app.
///
/// The bridge loads the chat page, passes chat events to `onEvent`, and opens
/// links from chat answers in the system browser, so the chat stays on screen.
@MainActor
public final class AsyntaiWebViewBridge: NSObject {

    public let configuration: AsyntaiConfiguration
    public var onEvent: ((AsyntaiChatPage.Event) -> Void)?
    public private(set) var webView: WKWebView?

    public init(configuration: AsyntaiConfiguration, onEvent: ((AsyntaiChatPage.Event) -> Void)? = nil) {
        self.configuration = configuration
        self.onEvent = onEvent
        super.init()
    }

    /// Makes the web view and starts to load the chat. Call it one time.
    public func makeWebView() -> WKWebView {
        if let existing = webView { return existing }

        let contentController = WKUserContentController()
        contentController.add(WeakMessageHandler(self), name: AsyntaiChatPage.messageHandlerName)

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        webConfiguration.websiteDataStore = .default()
        #if canImport(UIKit)
        webConfiguration.allowsInlineMediaPlayback = true
        #endif

        let view = WKWebView(frame: .zero, configuration: webConfiguration)
        view.navigationDelegate = self
        view.uiDelegate = self
        #if canImport(UIKit)
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isOpaque = false
        view.backgroundColor = .white
        #endif

        view.loadHTMLString(AsyntaiChatPage.html(for: configuration), baseURL: configuration.pageURL)
        webView = view
        return view
    }

    /// Opens the chat window.
    public func open() {
        webView?.evaluateJavaScript(AsyntaiChatPage.openScript, completionHandler: nil)
    }

    /// Closes the chat window.
    public func close() {
        webView?.evaluateJavaScript(AsyntaiChatPage.closeScript, completionHandler: nil)
    }

    /// Removes the message handler. The views call it when they go away.
    public func tearDown() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: AsyntaiChatPage.messageHandlerName)
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
    }

    fileprivate func receive(_ body: Any) {
        guard let event = AsyntaiChatPage.event(fromMessageBody: body) else { return }
        onEvent?(event)
    }

    fileprivate static func openExternally(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

extension AsyntaiWebViewBridge: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // The chat page itself loads from a string. Every link the visitor
        // taps in an answer opens in the system browser instead.
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            AsyntaiWebViewBridge.openExternally(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

extension AsyntaiWebViewBridge: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Links with target="_blank" and window.open() also go to the browser.
        if let url = navigationAction.request.url {
            AsyntaiWebViewBridge.openExternally(url)
        }
        return nil
    }
}

/// `WKUserContentController` keeps a strong reference to its handlers. This
/// wrapper holds the bridge weakly, so the web view never keeps it alive.
@MainActor
private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var bridge: AsyntaiWebViewBridge?

    init(_ bridge: AsyntaiWebViewBridge) {
        self.bridge = bridge
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        bridge?.receive(message.body)
    }
}
#endif
