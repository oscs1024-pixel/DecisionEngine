// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DecisionEngine",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DecisionEngineCore", targets: ["DecisionEngineCore"]),
        .library(name: "DecisionEngineMLX", targets: ["DecisionEngineMLX"]),
        .executable(name: "decision-engine-mcp", targets: ["DecisionEngineMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", branch: "main"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
    ],
    targets: [
        .target(name: "DecisionEngineCore"),
        .target(
            name: "DecisionEngineMLX",
            dependencies: [
                "DecisionEngineCore",
                .product(name: "MLX", package: "mlx-swift-lm"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXLMTokenizers", package: "mlx-swift-lm")
            ]
        ),
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
