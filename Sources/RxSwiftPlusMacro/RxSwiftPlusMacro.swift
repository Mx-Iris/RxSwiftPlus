import Foundation
@_exported import RxRelay
@_exported import RxSwiftPlus

@attached(member, names: arbitrary)
public macro ReactiveExtension() = #externalMacro(module: "RxSwiftPlusMacroPlugin", type: "ReactiveExtensionMacro")

/// Turns a stored property of a class into an observable one, the way
/// `@ObservationTracked` does, with a lazily created `BehaviorRelay` as the
/// projection:
///
/// ```swift
/// final class ViewModel {
///     @RxObserved public private(set) var title: String = ""
/// }
/// ```
///
/// expands to a `get` / `set` / `init` accessor triple over a private
/// `_title: RxObservedSlot<String>` stored inline in the object, plus a
/// `public var $title: BehaviorRelay<String>` that creates the relay on first
/// access and seeds it with the current value. Reading and writing `title`
/// never touches the relay; only `$title` does. That is what keeps a type
/// instantiated in bulk cheap: an unobserved property costs its value and one
/// nil reference.
///
/// Compared with the `@Observed` property wrapper, the storage is not
/// synchronized — like `@Observable`, the enclosing type owns its isolation —
/// and the declaration needs an explicit type annotation so the projection can
/// be typed. Classes and actors only; `let`, `static`, `lazy`, `weak` and
/// computed properties are rejected with a diagnostic.
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro RxObserved() = #externalMacro(module: "RxSwiftPlusMacroPlugin", type: "RxObservedMacro")
