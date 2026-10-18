// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AsyntaiAIChatbot",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(name: "AsyntaiAIChatbot", targets: ["AsyntaiAIChatbot"]),
    ],
    targets: [
        .target(name: "AsyntaiAIChatbot"),
        .testTarget(name: "AsyntaiAIChatbotTests", dependencies: ["AsyntaiAIChatbot"]),
    ]
)
