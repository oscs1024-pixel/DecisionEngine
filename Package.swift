// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DecisionEngine",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DecisionEngineCore", targets: ["DecisionEngineCore"]),
        .executable(name: "decision-engine-mcp", targets: ["DecisionEngineMCP"])
    ],
    targets: [
        .target(name: "DecisionEngineCore"),
        .executableTarget(name: "DecisionEngineMCP", dependencies: ["DecisionEngineCore"]),
        .testTarget(name: "DecisionEngineCoreTests", dependencies: ["DecisionEngineCore"])
    ]
)
