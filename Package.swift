// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainProperty",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "KeychainProperty",
            targets: ["KeychainProperty"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2")
    ],
    targets: [
        .target(
            name: "KeychainProperty",
            dependencies: [
                "KeychainAccess"
            ]
        ),
        .testTarget(
            name: "KeychainPropertyTests",
            dependencies: ["KeychainProperty"]
        )
    ]
)
