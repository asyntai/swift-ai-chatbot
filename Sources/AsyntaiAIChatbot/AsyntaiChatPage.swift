import Foundation

/// Builds the small HTML page that the web view loads. The page loads the
/// Asyntai widget script, opens the chat when the widget is ready, and tells
/// the app when the visitor opens or closes the chat.
///
/// This type uses only Foundation, so it builds and is tested on every
/// platform, also where WebKit is not available.
public enum AsyntaiChatPage {

    /// The name of the `WKScriptMessageHandler` that receives chat events.
    public static let messageHandlerName = "asyntai"

    /// The events the page sends to the app.
    public enum Event: String, Sendable {
        case ready
        case opened
        case closed
    }

    /// Returns the event for a message body from the page, or nil.
    public static func event(fromMessageBody body: Any) -> Event? {
        guard let text = body as? String else { return nil }
        return Event(rawValue: text)
    }

    /// The full HTML document for `configuration`.
    public static func html(for configuration: AsyntaiConfiguration) -> String {
        let widgetId = javaScriptString(configuration.widgetId)
        let scriptURL = javaScriptString(configuration.scriptURL.absoluteString)
        let openFlag = configuration.opensAutomatically ? "true" : "false"
        let handler = javaScriptString(messageHandlerName)

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
        <title>Chat</title>
        <style>html,body{margin:0;padding:0;height:100%;background:#ffffff;}</style>
        </head>
        <body>
        <script data-asyntai-app-bridge>
        (function () {
          var handlerName = \(handler);
          var openOnReady = \(openFlag);
          function send(name) {
            try {
              var handlers = window.webkit && window.webkit.messageHandlers;
              if (handlers && handlers[handlerName]) { handlers[handlerName].postMessage(name); }
            } catch (e) {}
          }
          function watch(widgetId) {
            var host = document.getElementById("asyntai-widget-host-" + widgetId);
            var root = host && host.shadowRoot;
            var box = root && root.querySelector(".mccs-chat-container");
            if (!box || !window.MutationObserver) { return; }
            var wasOpen = box.classList.contains("mccs-active");
            new MutationObserver(function () {
              var isOpen = box.classList.contains("mccs-active");
              if (isOpen !== wasOpen) { wasOpen = isOpen; send(isOpen ? "opened" : "closed"); }
            }).observe(box, { attributes: true, attributeFilter: ["class"] });
            if (wasOpen) { send("opened"); }
          }
          window.addEventListener("asyntai:ready", function (event) {
            var id = (event.detail && event.detail.widgetId) || \(widgetId);
            watch(id);
            send("ready");
            if (openOnReady && window.AsyntaiWidget) { window.AsyntaiWidget.open(); }
          });
          var s = document.createElement("script");
          s.src = \(scriptURL);
          s.async = true;
          s.setAttribute("data-asyntai-id", \(widgetId));
          document.head.appendChild(s);
        })();
        </script>
        </body>
        </html>
        """
    }

    /// The JavaScript to open the chat in a page that is already loaded.
    public static let openScript = "window.AsyntaiWidget && window.AsyntaiWidget.open();"

    /// The JavaScript to close the chat in a page that is already loaded.
    public static let closeScript = "window.AsyntaiWidget && window.AsyntaiWidget.close();"

    /// A double-quoted JavaScript string literal for `value`. `<`, `>` and `&`
    /// are escaped too, so a value can never close the script tag early.
    static func javaScriptString(_ value: String) -> String {
        var out = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case "<": out += "\\u003c"
            case ">": out += "\\u003e"
            case "&": out += "\\u0026"
            case "\u{2028}": out += "\\u2028"
            case "\u{2029}": out += "\\u2029"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        out += "\""
        return out
    }
}
