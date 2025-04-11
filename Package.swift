// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RxSwiftPlus",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "RxSwiftPlus",
            targets: ["RxSwiftPlus"]
        ),
        .library(
            name: "RxKingfisherPlus",
            targets: ["RxKingfisherPlus"]
        ),
        .library(
            name: "RxDefaultsPlus",
            targets: ["RxDefaultsPlus"]
        ),
        .library(
            name: "RxSwiftPlusMacro",
            targets: ["RxSwiftPlusMacro"]
        ),
    ],
    dependencies: [
        .RxSwift,
        .Kingfisher,
        .SwiftSyntax,
    ],
    targets: [
        .target(
            name: "RxSwiftPlus",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
            ]
        ),
        .target(
            name: "RxKingfisherPlus",
            dependencies: [
                "RxSwiftPlus",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ]
        ),
        .target(
            name: "RxDefaultsPlus",
            dependencies: [
                "RxSwiftPlus",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
//                .product(name: "Defaults", package: "Defaults"),
            ]
        ),
        .target(
            name: "RxSwiftPlusMacro",
            dependencies: [
                "RxSwiftPlusMacroPlugin",
            ]
        ),
        .macro(
            name: "RxSwiftPlusMacroPlugin",
            dependencies: [
                .SwiftSyntax,
                .SwiftSyntaxMacros,
                .SwiftCompilerPlugin,
                .SwiftSyntaxBuilder,
            ]
        ),
        .testTarget(
            name: "RxSwiftPlusTests",
            dependencies: [
                "RxSwiftPlus",
            ]
        ),
    ]
)

extension Package.Dependency {
    static let SwiftSyntax = Package.Dependency.package(
        url: "https://github.com/swiftlang/swift-syntax.git",
        from: "601.0.1"
    )
    static let Kingfisher = Package.Dependency.package(
        url: "https://github.com/onevcat/Kingfisher",
        .upToNextMajor(from: "8.0.0")
    )
    static let RxSwift = Package.Dependency.package(
        url: "https://github.com/ReactiveX/RxSwift",
        .upToNextMajor(from: "6.0.0")
    )
}

extension Target.Dependency {
    static let SwiftSyntax = Target.Dependency.product(
        name: "SwiftSyntax",
        package: "swift-syntax"
    )
    static let SwiftSyntaxMacros = Target.Dependency.product(
        name: "SwiftSyntaxMacros",
        package: "swift-syntax"
    )
    static let SwiftCompilerPlugin = Target.Dependency.product(
        name: "SwiftCompilerPlugin",
        package: "swift-syntax"
    )
    static let SwiftSyntaxBuilder = Target.Dependency.product(
        name: "SwiftSyntaxBuilder",
        package: "swift-syntax"
    )
    static let SwiftSyntaxMacrosTestSupport = Target.Dependency.product(
        name: "SwiftSyntaxMacrosTestSupport",
        package: "swift-syntax"
    )
}
