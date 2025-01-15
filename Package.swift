// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Viralloop",  // Changed to uppercase V
    platforms: [
        .iOS(.v13),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Viralloop",  // Changed to uppercase V
            targets: ["Viralloop"]),  // Changed to uppercase V
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Viralloop",  // Changed to uppercase V
            dependencies: []),
        .testTarget(
            name: "ViralloopTests",  // Changed to uppercase V
            dependencies: ["Viralloop"])  // Changed to uppercase V
    ]
)
