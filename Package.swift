// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DecisionEngine",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DecisionEngineCore", targets: ["DecisionEngineCore"]),
        .executable(name: "decision-engine-mcp", targets: ["DecisionEngineMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
    ],
    targets: [
        .target(name: "DecisionEngineCore"),
        .executableTarget(
            name: "DecisionEngineMCP",
            dependencies: [
                "DecisionEngineCore",
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(name: "DecisionEngineCoreTests", dependencies: ["DecisionEngineCore"])
    ]
)
