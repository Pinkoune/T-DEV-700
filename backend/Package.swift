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
<<<<<<< HEAD
        // JWT package for authentication
=======
        // Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // Leaf
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),
        // Firebase SDK officiel (commenté pour la démonstration)
        // .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        // dotenv package
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.0.0"),
        // JWT package
>>>>>>> 3cf58da (solution provisoire en rapport Firebase)
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        // Bcrypt package for secure password hashing
        .package(url: "https://github.com/vapor/bcrypt.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "backend",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
<<<<<<< HEAD
=======
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Leaf", package: "leaf"),
                // .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
>>>>>>> 3cf58da (solution provisoire en rapport Firebase)
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
