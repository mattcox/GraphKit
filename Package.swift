// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "GraphKit",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6),
		.visionOS(.v1)
	],
	products: [
		.library(
			name: "GraphKit",
			targets: [
				"GraphKit"
			]
		),
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "GraphKit",
			swiftSettings: [
				.swiftLanguageMode(.v6)
			]
		),
		.testTarget(
			name: "GraphKitTests",
			dependencies: [
				"GraphKit"
			],
			sources: ["GraphKit"],
			swiftSettings: [
				.swiftLanguageMode(.v6)
			]
		),
	]
)
