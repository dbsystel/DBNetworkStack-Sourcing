// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "DBNetworkStackSourcing",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_12),
        .tvOS(.v11),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "DBNetworkStackSourcing",
            targets: ["DBNetworkStackSourcing"])
    ],
    dependencies: [
        .package(url: "https://github.com/dbsystel/DBNetworkStack", from: "2.0.0"),
        .package(url: "https://github.com/lightsprint09/Sourcing", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "DBNetworkStackSourcing",
            dependencies: ["DBNetworkStack", "Sourcing"],
            path: "DBNetworkStack+Sourcing"),
        .testTarget(
            name: "DBNetworkStackSourcingTests",
            dependencies: ["DBNetworkStackSourcing"],
            path: "DBNetworkStack+SourcingTests")
    ]
)
