// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CleanArchitecture",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "CleanArchitecture",
            targets: ["CleanArchitecture"]
        ),
        .executable(
            name: "CleanArchitectureClient",
            targets: ["CleanArchitectureClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        .macro(
            name: "CleanArchitectureMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "CleanArchitecture",
            dependencies: ["CleanArchitectureMacros"]
        ),
        .executableTarget(
            name: "CleanArchitectureClient",
            dependencies: ["CleanArchitecture"]
        ),
        .testTarget(
            name: "CleanArchitectureTests",
            dependencies: [
                "CleanArchitectureMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
