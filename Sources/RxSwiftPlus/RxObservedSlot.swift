import RxRelay
import RxSwift

/// Inline storage behind a `@RxObserved` property: the current value plus the
/// `BehaviorRelay` that `$property` hands out, created on first access.
///
/// A value type on purpose. The `@Observed` property wrapper has to box its
/// state, because a struct's `nonmutating` setter cannot write inline storage.
/// The macro expands into accessors on the enclosing class instead, so the
/// slot can live in the object itself: an unobserved property costs its value
/// and one nil reference — no allocation, no lock.
///
/// Synchronization is the enclosing type's job, exactly as with `@Observable`:
/// the slot performs plain loads and stores. Once `relay` exists it is the
/// source of truth (`bind(to: $property)` writes go straight into it), so
/// `currentValue` prefers it.
///
/// The generated accessors never call into the relay while an access to the
/// slot is in progress — `accept` runs on a copied reference after the store —
/// so a subscriber that reads the property synchronously does not trip Swift's
/// exclusivity enforcement.
public struct RxObservedSlot<Value> {
    /// The value written through the property before `relay` exists. Stale
    /// once it does; read `currentValue`.
    public var value: Value

    /// The projected relay, `nil` until `$property` is first accessed.
    public var relay: BehaviorRelay<Value>?

    public init(_ value: Value) {
        self.value = value
        self.relay = nil
    }

    public var currentValue: Value {
        if let relay {
            return relay.value
        }
        return value
    }

    /// Whether `$property` has been materialized. Lets a test prove that a
    /// code path stayed on the property and never reached for the relay.
    public var hasMaterializedRelay: Bool {
        relay != nil
    }
}

extension RxObservedSlot: @unchecked Sendable where Value: Sendable {}
