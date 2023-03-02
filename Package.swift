// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let platforms: [SupportedPlatform] = [.iOS(.v13), .macOS(.v10_15)]
let package = Package(
    name: "aws-solution-clickstream-swift",
    platforms: platforms,
    products: [
        .library(
            name: "Clickstream",
            targets: ["Clickstream"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift.git", exact: "2.4.0"),
    ],
    targets: [
        .target(
            name: "Clickstream",
            dependencies: [
                .product(name: "AWSPluginsCore", package: "amplify-swift"),
            ]),
        .testTarget(
            name: "ClickstreamTests",
            dependencies: ["Clickstream"]),
    ])
