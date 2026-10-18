#if canImport(WebKit) && canImport(SwiftUI)
import SwiftUI
import WebKit

/// A SwiftUI view that shows the Asyntai AI chatbot.
///
/// ```swift
/// AsyntaiChatView(configuration: try! AsyntaiConfiguration(widgetId: "asyntai_1a2b3c4d5e6f"))
/// ```
///
/// Use `onEvent` to react when the visitor closes the chat, for example to
/// dismiss a sheet.
@available(iOS 14.0, macOS 11.0, *)
public struct AsyntaiChatView {
    public let configuration: AsyntaiConfiguration
    public let onEvent: ((AsyntaiChatPage.Event) -> Void)?

    public init(configuration: AsyntaiConfiguration, onEvent: ((AsyntaiChatPage.Event) -> Void)? = nil) {
        self.configuration = configuration
        self.onEvent = onEvent
    }

    @MainActor
    public final class Coordinator {
        let bridge: AsyntaiWebViewBridge

        init(configuration: AsyntaiConfiguration, onEvent: ((AsyntaiChatPage.Event) -> Void)?) {
            bridge = AsyntaiWebViewBridge(configuration: configuration, onEvent: onEvent)
        }
    }

    @MainActor
    public func makeCoordinator() -> Coordinator {
        Coordinator(configuration: configuration, onEvent: onEvent)
    }
}

#if canImport(UIKit)
@available(iOS 14.0, *)
extension AsyntaiChatView: UIViewRepresentable {
    public func makeUIView(context: Context) -> WKWebView {
        context.coordinator.bridge.makeWebView()
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.bridge.onEvent = onEvent
    }

    public static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.bridge.tearDown()
    }
}
#elseif canImport(AppKit)
@available(macOS 11.0, *)
extension AsyntaiChatView: NSViewRepresentable {
    public func makeNSView(context: Context) -> WKWebView {
        context.coordinator.bridge.makeWebView()
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.bridge.onEvent = onEvent
    }

    public static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        coordinator.bridge.tearDown()
    }
}
#endif
#endif
