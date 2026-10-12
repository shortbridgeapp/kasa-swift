// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KasaSwift",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "KasaSwift",
            targets: ["KasaSwift"]
        ),
    ],
    targets: [
        .target(
            name: "KasaSwift",
            dependencies: []
        )
    ]
)
