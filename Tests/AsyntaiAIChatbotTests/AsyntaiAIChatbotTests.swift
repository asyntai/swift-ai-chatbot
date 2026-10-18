import XCTest
@testable import AsyntaiAIChatbot

final class AsyntaiConfigurationTests: XCTestCase {

    func testValidWidgetId() throws {
        let config = try AsyntaiConfiguration(widgetId: "asyntai_1a2b3c4d5e6f")
        XCTAssertEqual(config.widgetId, "asyntai_1a2b3c4d5e6f")
        XCTAssertEqual(config.scriptURL, AsyntaiConfiguration.defaultScriptURL)
        XCTAssertEqual(config.pageURL, AsyntaiConfiguration.defaultPageURL)
        XCTAssertTrue(config.opensAutomatically)
    }

    func testWidgetIdIsTrimmed() throws {
        let config = try AsyntaiConfiguration(widgetId: "  asyntai_abc123\n")
        XCTAssertEqual(config.widgetId, "asyntai_abc123")
    }

    func testMissingWidgetIdThrows() {
        XCTAssertThrowsError(try AsyntaiConfiguration(widgetId: "")) { error in
            XCTAssertEqual(error as? AsyntaiConfigurationError, .missingWidgetId)
        }
        XCTAssertThrowsError(try AsyntaiConfiguration(widgetId: "   ")) { error in
            XCTAssertEqual(error as? AsyntaiConfigurationError, .missingWidgetId)
        }
    }

    func testBadWidgetIdsThrow() {
        for bad in ["1a2b3c", "asyntai_", "Asyntai_abc", "asyntai-abc", "asyntai_abc def", "asyntai_abc\"", "asyntai_ab<c", "asyntai_ábc"] {
            XCTAssertThrowsError(try AsyntaiConfiguration(widgetId: bad), bad) { error in
                XCTAssertEqual(error as? AsyntaiConfigurationError, .invalidWidgetId(bad.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
    }

    func testErrorMessagesSayWhatToDo() {
        XCTAssertTrue(AsyntaiConfigurationError.missingWidgetId.description.contains("Install page"))
        XCTAssertTrue(AsyntaiConfigurationError.invalidWidgetId("x").description.contains("asyntai_"))
    }

    func testNonHttpScriptURLThrows() {
        let fileURL = URL(string: "file:///tmp/widget.js")!
        XCTAssertThrowsError(try AsyntaiConfiguration(widgetId: "asyntai_abc", scriptURL: fileURL)) { error in
            XCTAssertEqual(error as? AsyntaiConfigurationError, .invalidScriptURL(fileURL))
        }
    }

    func testNonHttpPageURLThrows() {
        let pageURL = URL(string: "about:blank")!
        XCTAssertThrowsError(try AsyntaiConfiguration(widgetId: "asyntai_abc", pageURL: pageURL)) { error in
            XCTAssertEqual(error as? AsyntaiConfigurationError, .invalidPageURL(pageURL))
        }
    }

    func testCustomURLsAndFlag() throws {
        let script = URL(string: "http://127.0.0.1:8000/static/js/chat-widget.js")!
        let page = URL(string: "https://shop.example.com/")!
        let config = try AsyntaiConfiguration(widgetId: "asyntai_abc", pageURL: page, scriptURL: script, opensAutomatically: false)
        XCTAssertEqual(config.scriptURL, script)
        XCTAssertEqual(config.pageURL, page)
        XCTAssertFalse(config.opensAutomatically)
    }
}

final class AsyntaiChatPageTests: XCTestCase {

    private func page(_ opens: Bool = true) throws -> String {
        AsyntaiChatPage.html(for: try AsyntaiConfiguration(widgetId: "asyntai_1a2b3c4d5e6f", opensAutomatically: opens))
    }

    func testPageIsAFullDocument() throws {
        let html = try page()
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<meta name=\"viewport\""))
        XCTAssertTrue(html.hasSuffix("</html>"))
    }

    func testPageLoadsTheWidgetScriptOnce() throws {
        let html = try page()
        XCTAssertTrue(html.contains("s.src = \"https://widget.asyntai.com/static/js/chat-widget.js\";"))
        XCTAssertTrue(html.contains("s.setAttribute(\"data-asyntai-id\", \"asyntai_1a2b3c4d5e6f\");"))
        XCTAssertEqual(html.components(separatedBy: "document.createElement(\"script\")").count - 1, 1)
        XCTAssertEqual(html.components(separatedBy: "<script").count - 1, 1)
    }

    func testPageOpensChatWhenReady() throws {
        XCTAssertTrue(try page(true).contains("var openOnReady = true;"))
        XCTAssertTrue(try page(false).contains("var openOnReady = false;"))
        XCTAssertTrue(try page().contains("window.addEventListener(\"asyntai:ready\""))
        XCTAssertTrue(try page().contains("window.AsyntaiWidget.open()"))
    }

    func testPageTalksToTheMessageHandler() throws {
        let html = try page()
        XCTAssertEqual(AsyntaiChatPage.messageHandlerName, "asyntai")
        XCTAssertTrue(html.contains("var handlerName = \"asyntai\";"))
        for event in ["ready", "opened", "closed"] {
            XCTAssertTrue(html.contains("\"\(event)\""), event)
        }
        XCTAssertTrue(html.contains(".mccs-chat-container"))
        XCTAssertTrue(html.contains("asyntai-widget-host-"))
    }

    func testEventParsing() {
        XCTAssertEqual(AsyntaiChatPage.event(fromMessageBody: "ready"), .ready)
        XCTAssertEqual(AsyntaiChatPage.event(fromMessageBody: "opened"), .opened)
        XCTAssertEqual(AsyntaiChatPage.event(fromMessageBody: "closed"), .closed)
        XCTAssertNil(AsyntaiChatPage.event(fromMessageBody: "other"))
        XCTAssertNil(AsyntaiChatPage.event(fromMessageBody: 42))
    }

    func testScriptURLIsEscaped() throws {
        let tricky = URL(string: "https://example.com/w.js?a=%3C/script%3E&b=1")!
        let html = AsyntaiChatPage.html(for: try AsyntaiConfiguration(widgetId: "asyntai_abc", scriptURL: tricky))
        XCTAssertFalse(html.contains("</script><"))
        XCTAssertTrue(html.contains("\\u0026b=1"))
    }

    func testJavaScriptStringEscaping() {
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("abc"), "\"abc\"")
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("a\"b"), "\"a\\\"b\"")
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("a\\b"), "\"a\\\\b\"")
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("</script>"), "\"\\u003c/script\\u003e\"")
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("a\nb"), "\"a\\nb\"")
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("\u{2028}"), "\"\\u2028\"")
        XCTAssertEqual(AsyntaiChatPage.javaScriptString("\u{01}"), "\"\\u0001\"")
    }

    func testOpenAndCloseScripts() {
        XCTAssertEqual(AsyntaiChatPage.openScript, "window.AsyntaiWidget && window.AsyntaiWidget.open();")
        XCTAssertEqual(AsyntaiChatPage.closeScript, "window.AsyntaiWidget && window.AsyntaiWidget.close();")
    }
}
