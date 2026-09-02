import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@RxObserved var name: Type = initial` — accessors over an inline
/// `RxObservedSlot`, plus a `$name` relay projection created on first access.
public enum RxObservedMacro {}

// MARK: - Accessor role

extension RxObservedMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // The peer role reports every problem; this role stays silent so a bad
        // declaration produces one diagnostic, not two.
        guard let property = ObservedProperty.parse(declaration, attribute: node, context: context, reportingDiagnostics: false) else {
            return []
        }
        let storage = property.storageName
        return [
            """
            @storageRestrictions(initializes: \(storage))
            init(initialValue) {
                \(storage) = RxSwiftPlus.RxObservedSlot(initialValue)
            }
            """,
            """
            get {
                \(storage).currentValue
            }
            """,
            """
            set {
                \(storage).value = newValue
                let relay = \(storage).relay
                relay?.accept(newValue)
            }
            """,
        ]
    }
}

// MARK: - Peer role

extension RxObservedMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let property = ObservedProperty.parse(declaration, attribute: node, context: context, reportingDiagnostics: true) else {
            return []
        }
        let storage = property.storageName
        let projection = property.projectionName
        let valueType = property.valueType

        let storageDeclaration: DeclSyntax
        if property.storageDefaultsToNil {
            storageDeclaration = "private var \(storage): RxSwiftPlus.RxObservedSlot<\(valueType)> = RxSwiftPlus.RxObservedSlot(nil)"
        } else {
            storageDeclaration = "private var \(storage): RxSwiftPlus.RxObservedSlot<\(valueType)>"
        }

        let projectionDeclaration: DeclSyntax = """
            \(raw: property.projectionAccessModifier)var \(projection): RxRelay.BehaviorRelay<\(valueType)> {
                if let relay = \(storage).relay {
                    return relay
                }
                let relay = RxRelay.BehaviorRelay(value: \(storage).value)
                \(storage).relay = relay
                return relay
            }
            """
        return [storageDeclaration, projectionDeclaration]
    }
}

// MARK: - Declaration analysis

private struct ObservedProperty {
    let storageName: TokenSyntax
    let projectionName: TokenSyntax
    let valueType: TypeSyntax
    /// `true` when the property has no initializer and an optional type: the
    /// storage then defaults to `nil` the way a plain optional stored property
    /// would, instead of forcing every initializer to assign it.
    let storageDefaultsToNil: Bool
    /// The access modifier for `$name`, e.g. `"public "`; empty for internal.
    let projectionAccessModifier: String

    static func parse(
        _ declaration: some DeclSyntaxProtocol,
        attribute: AttributeSyntax,
        context: some MacroExpansionContext,
        reportingDiagnostics: Bool
    ) -> ObservedProperty? {
        func reject(_ diagnostic: RxObservedDiagnostic, at node: some SyntaxProtocol) -> ObservedProperty? {
            if reportingDiagnostics {
                context.diagnose(Diagnostic(node: Syntax(node), message: diagnostic))
            }
            return nil
        }

        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            return reject(.notAVariable, at: attribute)
        }
        guard variable.bindingSpecifier.tokenKind == .keyword(.var) else {
            return reject(.constant, at: variable.bindingSpecifier)
        }
        guard variable.bindings.count == 1, let binding = variable.bindings.first else {
            return reject(.multipleBindings, at: variable.bindings)
        }
        guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return reject(.notAnIdentifier, at: binding.pattern)
        }
        guard binding.accessorBlock == nil else {
            return reject(.computed, at: binding)
        }
        guard let annotatedType = binding.typeAnnotation?.type else {
            return reject(.missingType, at: binding)
        }
        for modifier in variable.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.static), .keyword(.class):
                return reject(.staticProperty, at: modifier)
            case .keyword(.lazy):
                return reject(.lazyProperty, at: modifier)
            case .keyword(.weak), .keyword(.unowned):
                return reject(.referenceQualified, at: modifier)
            default:
                break
            }
        }
        if let enclosingDeclaration = context.lexicalContext.first,
           !enclosingDeclaration.is(ClassDeclSyntax.self),
           !enclosingDeclaration.is(ActorDeclSyntax.self)
        {
            return reject(.notInClass, at: attribute)
        }

        let propertyName = identifierPattern.identifier.trimmed.text
        let (valueType, isOptional) = normalize(annotatedType.trimmed)
        return ObservedProperty(
            storageName: .identifier("_\(propertyName)"),
            projectionName: .identifier("$\(propertyName)"),
            valueType: valueType,
            storageDefaultsToNil: binding.initializer == nil && isOptional,
            projectionAccessModifier: projectionAccessModifier(of: variable.modifiers)
        )
    }

    /// Spells implicitly unwrapped optionals as plain optionals, because the
    /// slot's generic argument and the relay's element type cannot carry `!`.
    private static func normalize(_ type: TypeSyntax) -> (type: TypeSyntax, isOptional: Bool) {
        if type.is(OptionalTypeSyntax.self) {
            return (type, true)
        }
        if let implicitlyUnwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return (TypeSyntax(OptionalTypeSyntax(wrappedType: implicitlyUnwrapped.wrappedType)), true)
        }
        if let identifierType = type.as(IdentifierTypeSyntax.self),
           identifierType.name.text == "Optional",
           identifierType.genericArgumentClause != nil
        {
            return (type, true)
        }
        return (type, false)
    }

    /// The property's getter access level. Setter-only modifiers such as
    /// `private(set)` carry a detail and are skipped; `open` becomes `public`
    /// because a computed peer is not overridable.
    private static func projectionAccessModifier(of modifiers: DeclModifierListSyntax) -> String {
        for modifier in modifiers where modifier.detail == nil {
            switch modifier.name.tokenKind {
            case .keyword(.open), .keyword(.public):
                return "public "
            case .keyword(.package):
                return "package "
            case .keyword(.fileprivate):
                return "fileprivate "
            case .keyword(.private):
                return "private "
            case .keyword(.internal):
                return ""
            default:
                continue
            }
        }
        return ""
    }
}

// MARK: - Diagnostics

private enum RxObservedDiagnostic: String, DiagnosticMessage {
    case notAVariable
    case constant
    case multipleBindings
    case notAnIdentifier
    case computed
    case missingType
    case staticProperty
    case lazyProperty
    case referenceQualified
    case notInClass

    var message: String {
        switch self {
        case .notAVariable:
            return "@RxObserved can only be applied to a stored property"
        case .constant:
            return "@RxObserved requires 'var'; a 'let' cannot change and has nothing to observe"
        case .multipleBindings:
            return "@RxObserved must be applied to a single property declaration"
        case .notAnIdentifier:
            return "@RxObserved requires a simple property name"
        case .computed:
            return "@RxObserved cannot be applied to a computed property"
        case .missingType:
            return "@RxObserved requires an explicit type annotation so the '$' projection can be typed"
        case .staticProperty:
            return "@RxObserved cannot be applied to a static property"
        case .lazyProperty:
            return "@RxObserved cannot be applied to a lazy property"
        case .referenceQualified:
            return "@RxObserved cannot be applied to a weak or unowned property"
        case .notInClass:
            return "@RxObserved can only be used inside a class or actor"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "RxSwiftPlusMacroPlugin", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
