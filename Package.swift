// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MisuseOfNotation",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "MisuseOfNotation", targets: ["MisuseOfNotation"]),
        .executable(name: "MisuseOfNotationClient", targets: ["MisuseOfNotationClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(name: "MisuseOfNotationMacros", dependencies: [
            .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]),
        .target(name: "MisuseOfNotation", dependencies: ["MisuseOfNotationMacros"]),
        .executableTarget(name: "MisuseOfNotationClient", dependencies: ["MisuseOfNotation"]),
        .testTarget(name: "MisuseOfNotationMacrosTests", dependencies: [
            "MisuseOfNotationMacros",
            .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        ]),
    ]
)
