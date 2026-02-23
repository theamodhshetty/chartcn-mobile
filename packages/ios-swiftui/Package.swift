// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "ChartCNMobile",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(name: "ChartCNMobile", targets: ["ChartCNMobile"])
  ],
  targets: [
    .target(name: "ChartCNMobile"),
    .testTarget(name: "ChartCNMobileTests", dependencies: ["ChartCNMobile"])
  ]
)
