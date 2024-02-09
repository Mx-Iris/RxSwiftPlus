import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

@attached(member, names: arbitrary)
public macro ReactiveExtension() = #externalMacro(module: "RxSwiftPlusMacroPlugin", type: "ReactiveExtensionMacro")
