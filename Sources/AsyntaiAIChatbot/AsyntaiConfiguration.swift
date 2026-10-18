import Foundation

/// Settings for the Asyntai chat. Only `widgetId` is required.
///
/// Copy the widget ID from the Install page of your Asyntai dashboard
/// (https://asyntai.com/dashboard). It looks like `asyntai_1a2b3c4d5e6f`.
public struct AsyntaiConfiguration: Equatable, Sendable {

    /// The default address of the Asyntai widget script.
    public static let defaultScriptURL = URL(string: "https://widget.asyntai.com/static/js/chat-widget.js")!

    /// The default page address the chat reports. Set `pageURL` to your own
    /// website if you want app chats to show your site in the dashboard.
    public static let defaultPageURL = URL(string: "https://asyntai.com/")!

    /// The widget ID, for example `asyntai_1a2b3c4d5e6f`.
    public let widgetId: String

    /// The page address the chat runs on. It is the base URL of the web view.
    public let pageURL: URL

    /// The widget script address. Change it only for testing.
    public let scriptURL: URL

    /// Opens the chat window as soon as the widget is ready. When `false`,
    /// the page shows the chat button and the visitor taps it.
    public let opensAutomatically: Bool

    /// Makes a configuration, or throws `AsyntaiConfigurationError` when the
    /// widget ID is missing or does not look like a widget ID.
    public init(
        widgetId: String,
        pageURL: URL = AsyntaiConfiguration.defaultPageURL,
        scriptURL: URL = AsyntaiConfiguration.defaultScriptURL,
        opensAutomatically: Bool = true
    ) throws {
        let trimmed = widgetId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AsyntaiConfigurationError.missingWidgetId
        }
        guard AsyntaiConfiguration.isValidWidgetId(trimmed) else {
            throw AsyntaiConfigurationError.invalidWidgetId(trimmed)
        }
        guard let scheme = scriptURL.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            throw AsyntaiConfigurationError.invalidScriptURL(scriptURL)
        }
        guard let pageScheme = pageURL.scheme?.lowercased(), pageScheme == "https" || pageScheme == "http" else {
            throw AsyntaiConfigurationError.invalidPageURL(pageURL)
        }
        self.widgetId = trimmed
        self.pageURL = pageURL
        self.scriptURL = scriptURL
        self.opensAutomatically = opensAutomatically
    }

    /// True when `value` has the form `asyntai_` followed by letters and digits.
    public static func isValidWidgetId(_ value: String) -> Bool {
        let prefix = "asyntai_"
        guard value.hasPrefix(prefix) else { return false }
        let rest = value.dropFirst(prefix.count)
        guard !rest.isEmpty else { return false }
        return rest.unicodeScalars.allSatisfy { scalar in
            (scalar >= "a" && scalar <= "z") || (scalar >= "A" && scalar <= "Z") || (scalar >= "0" && scalar <= "9")
        }
    }
}

/// Why a configuration could not be made.
public enum AsyntaiConfigurationError: Error, Equatable, CustomStringConvertible {
    case missingWidgetId
    case invalidWidgetId(String)
    case invalidScriptURL(URL)
    case invalidPageURL(URL)

    public var description: String {
        switch self {
        case .missingWidgetId:
            return "AsyntaiAIChatbot: widgetId is required. Copy it from the Install page of your Asyntai dashboard, for example asyntai_1a2b3c4d5e6f."
        case .invalidWidgetId(let value):
            return "AsyntaiAIChatbot: \"\(value)\" does not look like a widget ID. It starts with asyntai_, for example asyntai_1a2b3c4d5e6f."
        case .invalidScriptURL(let url):
            return "AsyntaiAIChatbot: scriptURL must be an http or https address, not \(url.absoluteString)."
        case .invalidPageURL(let url):
            return "AsyntaiAIChatbot: pageURL must be an http or https address, not \(url.absoluteString)."
        }
    }
}
