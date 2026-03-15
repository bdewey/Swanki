// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Anki",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "Anki",
      targets: ["Anki"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "7.10.0")),
    .package(url: "https://github.com/bdewey/SpacedRepetitionScheduler.git", .upToNextMajor(from: "0.5.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Anki",
      dependencies: [
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "SpacedRepetitionScheduler", package: "SpacedRepetitionScheduler"),
      ]
    ),
    .testTarget(
      name: "AnkiTests",
      dependencies: ["Anki"]
    ),
  ]
)
