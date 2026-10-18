# Asyntai AI Chatbot for iOS and macOS

Add the [Asyntai](https://asyntai.com) AI chatbot to your iPhone, iPad or Mac
app. It answers your users from your own content, in more than 80 languages.
It is the same assistant as on your website, with the same knowledge, colours
and settings.

## Install

In Xcode, choose **File > Add Package Dependencies** and enter:

```
https://github.com/asyntai/swift-ai-chatbot.git
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/asyntai/swift-ai-chatbot.git", from: "1.0.0")
```

Then add the `AsyntaiAIChatbot` library to your target.

## SwiftUI

```swift
import SwiftUI
import AsyntaiAIChatbot

struct HelpButton: View {
    @State private var showChat = false
    private let chat = try! AsyntaiConfiguration(widgetId: "asyntai_1a2b3c4d5e6f")

    var body: some View {
        Button("Chat with us") { showChat = true }
            .sheet(isPresented: $showChat) {
                AsyntaiChatView(configuration: chat) { event in
                    if event == .closed { showChat = false }
                }
            }
    }
}
```

## UIKit

```swift
import AsyntaiAIChatbot

let config = try AsyntaiConfiguration(widgetId: "asyntai_1a2b3c4d5e6f")
present(AsyntaiChatViewController(configuration: config), animated: true)
```

The view controller closes itself when the user closes the chat. Set
`dismissesOnClose = false` to keep it on screen.

## Where the widget ID comes from

Open the Install page in your [Asyntai dashboard](https://asyntai.com/dashboard).
The widget ID is the value of `data-asyntai-id` in the snippet. It starts with
`asyntai_`.

## Options

| Option | Default | What it does |
| --- | --- | --- |
| `widgetId` | required | Your Asyntai widget ID |
| `pageURL` | `https://asyntai.com/` | The page address the chat reports. Set it to your website to see it on app chats in the dashboard |
| `opensAutomatically` | `true` | Opens the chat window at once. Set it to `false` to show the chat button first |
| `scriptURL` | the Asyntai CDN | Advanced. Load the widget from another URL |

A missing or malformed `widgetId` throws an `AsyntaiConfigurationError` with a
message that says how to fix it.

## Chat events

`onEvent` receives `.ready` when the chat has loaded, `.opened` when the chat
window opens, and `.closed` when the user closes it. Links in chat answers open
in the system browser, so the conversation stays in your app.

## Requirements

- iOS 14 or later, or macOS 11 or later
- Xcode 15 or later (Swift 5.9 or later)

## Documentation

Full guide: https://asyntai.com/documentation/integrations/swift/

## Tests

```bash
swift test
```

## License

MIT
