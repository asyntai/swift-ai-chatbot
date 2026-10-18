#if canImport(UIKit) && canImport(WebKit)
import UIKit
import WebKit

/// A UIKit view controller that shows the Asyntai AI chatbot full screen.
///
/// ```swift
/// let chat = AsyntaiChatViewController(configuration: try! AsyntaiConfiguration(widgetId: "asyntai_1a2b3c4d5e6f"))
/// present(chat, animated: true)
/// ```
///
/// When the visitor closes the chat, the controller dismisses itself if it
/// was presented. Set `dismissesOnClose` to `false` to keep it on screen.
open class AsyntaiChatViewController: UIViewController {

    public let bridge: AsyntaiWebViewBridge

    /// Dismisses a presented controller when the visitor closes the chat.
    public var dismissesOnClose = true

    /// Called for every chat event, after the controller handles it.
    public var onEvent: ((AsyntaiChatPage.Event) -> Void)?

    public init(configuration: AsyntaiConfiguration) {
        bridge = AsyntaiWebViewBridge(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        bridge.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported. Use init(configuration:).")
    }

    deinit {
        let bridge = self.bridge
        Task { @MainActor in bridge.tearDown() }
    }

    open override func loadView() {
        view = bridge.makeWebView()
    }

    /// Opens the chat window.
    public func openChat() {
        bridge.open()
    }

    /// Closes the chat window.
    public func closeChat() {
        bridge.close()
    }

    private func handle(_ event: AsyntaiChatPage.Event) {
        if event == .closed, dismissesOnClose, presentingViewController != nil {
            dismiss(animated: true)
        }
        onEvent?(event)
    }
}
#endif
