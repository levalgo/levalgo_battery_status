// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
  name: "levalgo_battery_status",
  platforms: [
    // iOS only, matching the podspec and the pubspec's platform declaration.
    .iOS("13.0")
  ],
  products: [
    // Swift Package Manager rejects "_" in a library name, so the library is
    // the "-" separated form while the target keeps the package name.
    .library(name: "levalgo-battery-status", targets: ["levalgo_battery_status"])
  ],
  dependencies: [
    // Provides Flutter.framework to the package. It resolves to a path the
    // Flutter tool generates next to this package at build time, which is why
    // it requires Flutter 3.41 or later.
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "levalgo_battery_status",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ],
      resources: [
        // The same manifest CocoaPods ships through resource_bundles. Both
        // dependency managers have to bundle it, each in its own way.
        .process("PrivacyInfo.xcprivacy")
      ]
    )
  ]
)
