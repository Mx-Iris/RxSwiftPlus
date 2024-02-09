import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RxSwiftPlusMacroPlugin: CompilerPlugin {
    var providingMacros: [Macro.Type] {
        [
            ReactiveExtensionMacro.self,
        ]
    }
}
