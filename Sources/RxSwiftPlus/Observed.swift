import RxSwift
import RxCocoa

@propertyWrapper
public final class Observed<Element> {
    private let storage: BehaviorRelay<Element>

    public var wrappedValue: Element {
        set {
            storage.accept(newValue)
        }
        get {
            storage.value
        }
    }

    public init(wrappedValue: Element) {
        self.storage = .init(value: wrappedValue)
    }

    public var projectedValue: BehaviorRelay<Element> {
        storage
    }
}
