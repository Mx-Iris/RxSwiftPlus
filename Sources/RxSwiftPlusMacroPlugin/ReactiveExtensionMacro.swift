import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public enum ReactiveExtensionMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        return [
            """
            /// Reactive extensions.
            public static var rx: Reactive<Self>.Type {
                get { Reactive<Self>.self }
                // this enables using Reactive to "mutate" base type
                // swiftlint:disable:next unused_setter_value
                set { }
            }
            """,
            """
            /// Reactive extensions.
            public var rx: Reactive<Self> {
                get { Reactive(self) }
                // this enables using Reactive to "mutate" base object
                // swiftlint:disable:next unused_setter_value
                set { }
            }
            """,
        ]
    }
}
