// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyPressEventManager",
    platforms: [
        .macOS(.v14),
//        .iOS(.v14),
//        .watchOS(.v8),
//        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KeyPressEventManager",
            targets: ["KeyPressEventManager"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KeyPressEventManager"),
        .testTarget(
            name: "KeyPressEventManagerTests",
            dependencies: ["KeyPressEventManager"]),
    ]
)
