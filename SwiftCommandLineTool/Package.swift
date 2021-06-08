// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCommandLineTool",
    platforms: [.macOS("10.12")],
    dependencies: [
        .package(name: "Alamofire",
                 url: "https://github.com/Alamofire/Alamofire.git",
                 from: "5.4.3")
    ],
    targets: [
        .target(
            name: "SwiftCommandLineTool",
            dependencies: ["Alamofire"]),
        .testTarget(
            name: "SwiftCommandLineToolTests",
            dependencies: ["SwiftCommandLineTool","Alamofire"]),
    ]
)
