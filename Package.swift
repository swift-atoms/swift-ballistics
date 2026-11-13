// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "swift-ballistics",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [.library(name: "Ballistics", targets: ["Ballistics"])],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-exponential.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Ballistics",
            dependencies: [
                .product(name: "Exponential", package: "swift-exponential")
            ]
        ),
        .testTarget(
            name: "Ballistics Tests",
            dependencies: [
                .target(name: "Ballistics")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
