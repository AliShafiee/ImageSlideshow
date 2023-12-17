// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ImageSlideshow",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ImageSlideshow",
            targets: ["ImageSlideshow"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.1"),
    ],
    targets: [
        .target(
            name: "ImageSlideshow",
            dependencies: ["Kingfisher"],
        path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
