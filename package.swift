// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "findmyfriends",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "App",
            targets: ["App"]
        )
    ],
    dependencies: [
        // any dependencies you might need
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [],
            path: "lib"   // <-- tells Swift to look in lib/ instead of Sources/App
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"]
        )
    ]
)