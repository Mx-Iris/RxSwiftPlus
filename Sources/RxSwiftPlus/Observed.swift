import os
import RxSwift
@preconcurrency import RxCocoa

/// Stores a value and exposes it as a `BehaviorRelay` through the projected
/// value (`$property`).
///
/// The relay is materialized lazily. Reading or writing `wrappedValue` only
/// touches an inline slot guarded by an unfair lock; the `BehaviorRelay` (and
/// the `BehaviorSubject` plus `NSRecursiveLock` it carries) is allocated the
/// first time `projectedValue` is accessed, seeded with the value at that
/// moment, and is the single source of truth from then on. A type that is
/// instantiated in bulk — one cell view model per row, say — therefore pays
/// for a relay only on the instances something actually observes.
///
/// The flip side: code that merely needs the current value must read
/// `wrappedValue`, never `$property.value`. The latter materializes the relay,
/// and doing so on every row of a bulk path silently undoes the saving.
@propertyWrapper
public struct Observed<Value> {
    private let storage: ObservedStorage<Value>

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.write(newValue) }
    }

    /// The backing relay, materialized on first access. Subscribing replays
    /// the current value and delivers every later write, exactly as a relay
    /// created eagerly would.
    public var projectedValue: BehaviorRelay<Value> {
        storage.relay()
    }

    /// Whether `projectedValue` has been materialized. Lets a test prove that
    /// a code path stayed on `wrappedValue` and never reached for the relay.
    public var hasMaterializedRelay: Bool {
        storage.hasMaterializedRelay
    }

    public init(wrappedValue: Value) {
        self.storage = ObservedStorage(initialValue: wrappedValue)
    }

    /// Wraps an existing relay, which counts as materialized from the start.
    public init(relay: BehaviorRelay<Value>) {
        self.storage = ObservedStorage(relay: relay)
    }
}

// `BehaviorRelay` is not `Sendable`. It is internally synchronized, and so is
// the inline slot; that is what this conformance vouches for.
extension Observed: @unchecked Sendable where Value: Sendable {}

extension Observed where Value: ExpressibleByNilLiteral {
    @inlinable public init() {
        self.init(wrappedValue: nil)
    }
}

/// Reference storage behind `Observed`. The wrapper is a struct with a
/// `nonmutating` setter, so its mutable state has to live in a class.
///
/// Lock discipline: the unfair lock guards `state` and nothing else. The
/// relay's own lock is never taken while this lock is held — a read copies the
/// relay reference out before asking it for the value, and a write forwards
/// `accept` after unlocking — so there is no lock-order cycle with a subscriber
/// that reads `wrappedValue` from inside `BehaviorSubject`'s subscribe replay.
/// Dispatching `accept` outside the lock also keeps RxSwift's re-entrancy
/// semantics: a subscriber may write the property back synchronously.
final class ObservedStorage<Value> {
    private enum State {
        case inline(Value)
        case materialized(BehaviorRelay<Value>)
    }

    private let lock: UnsafeMutablePointer<os_unfair_lock>

    private var state: State

    init(initialValue: Value) {
        self.lock = Self.makeLock()
        self.state = .inline(initialValue)
    }

    init(relay: BehaviorRelay<Value>) {
        self.lock = Self.makeLock()
        self.state = .materialized(relay)
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    var value: Value {
        os_unfair_lock_lock(lock)
        switch state {
        case .inline(let currentValue):
            os_unfair_lock_unlock(lock)
            return currentValue
        case .materialized(let relay):
            os_unfair_lock_unlock(lock)
            return relay.value
        }
    }

    func write(_ newValue: Value) {
        os_unfair_lock_lock(lock)
        switch state {
        case .inline:
            state = .inline(newValue)
            os_unfair_lock_unlock(lock)
        case .materialized(let relay):
            os_unfair_lock_unlock(lock)
            relay.accept(newValue)
        }
    }

    func relay() -> BehaviorRelay<Value> {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        switch state {
        case .inline(let currentValue):
            let relay = BehaviorRelay(value: currentValue)
            state = .materialized(relay)
            return relay
        case .materialized(let relay):
            return relay
        }
    }

    var hasMaterializedRelay: Bool {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        if case .materialized = state {
            return true
        }
        return false
    }

    private static func makeLock() -> UnsafeMutablePointer<os_unfair_lock> {
        let lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
        return lock
    }
}
