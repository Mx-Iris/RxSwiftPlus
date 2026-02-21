import RxSwift
import RxCocoa

@frozen
@propertyWrapper
public struct Observed<Value> {
    private let storage: BehaviorRelay<Value>

    public var wrappedValue: Value {
        nonmutating set {
            storage.accept(newValue)
        }
        get {
            storage.value
        }
    }

    public init(wrappedValue: Value) {
        self.storage = .init(value: wrappedValue)
    }

    public var projectedValue: BehaviorRelay<Value> {
        storage
    }
}

extension Observed: Sendable where Value: Sendable {}

extension Observed where Value: ExpressibleByNilLiteral {
    @inlinable public init() {
        self.init(wrappedValue: nil)
    }
}
