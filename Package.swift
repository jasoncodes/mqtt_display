// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mqtt_display",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/sroebert/mqtt-nio.git", from: "2.8.0"),
        .package(url: "https://github.com/tannerdsilva/SwiftSlash.git", from: "3.3.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "mqtt_display",
            dependencies: [
                .product(name: "MQTTNIO", package: "mqtt-nio"),
                "SwiftSlash",
            ]),
    ]
)
