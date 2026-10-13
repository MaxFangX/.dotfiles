// swift-tools-version:5.9
// For `swift build` and SourceKit-LSP; Nix calls swiftc directly.
import PackageDescription

let package = Package(
    name: "macctl",
    platforms: [.macOS(.v13)],
    targets: [.executableTarget(name: "macctl")]
)
