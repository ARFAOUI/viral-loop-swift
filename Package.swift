// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Viralloop",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Viralloop",
            targets: ["Viralloop"]),
    ],
    targets: [
        .target(
            name: "Viralloop",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("Network")
            ]
        )
    ]
)
