// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "backend",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // JWT package for authentication
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        // Bcrypt package for secure password hashing
        .package(url: "https://github.com/vapor/bcrypt.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "backend",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "BCrypt", package: "bcrypt"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "backendTests",
            dependencies: [
                .target(name: "backend"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
