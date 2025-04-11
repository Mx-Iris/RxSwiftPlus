import Foundation

@attached(member, names: arbitrary)
public macro ReactiveExtension() = #externalMacro(module: "RxSwiftPlusMacroPlugin", type: "ReactiveExtensionMacro")
