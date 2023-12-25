// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "filecrypt",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", from: "2.0.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "filecrypt",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Cryptor", package: "BlueCryptor"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ]
        ),
    ]
)
