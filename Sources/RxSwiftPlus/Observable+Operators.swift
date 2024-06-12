import Foundation
import RxSwift
import RxCocoa

public protocol OptionalType {
    associatedtype Wrapped

    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? {
        return self
    }
}

extension Observable where Element: OptionalType {
    public func filterNil() -> Observable<Element.Wrapped> {
        return flatMap { element -> Observable<Element.Wrapped> in
            if let value = element.value {
                return .just(value)
            } else {
                return .empty()
            }
        }
    }

    public func filterNilKeepOptional() -> Observable<Element> {
        return filter { element -> Bool in
            return element.value != nil
        }
    }

    public func replaceNil(with nilValue: Element.Wrapped) -> Observable<Element.Wrapped> {
        return flatMap { element -> Observable<Element.Wrapped> in
            if let value = element.value {
                return .just(value)
            } else {
                return .just(nilValue)
            }
        }
    }
}

extension SharedSequenceConvertibleType where Element: OptionalType {
    public func filterNil() -> SharedSequence<SharingStrategy, Element.Wrapped> {
        return flatMap { element -> SharedSequence<SharingStrategy, Element.Wrapped> in
            if let value = element.value {
                return .just(value)
            } else {
                return .empty()
            }
        }
    }

    public func filterNilKeepOptional() -> SharedSequence<SharingStrategy, Element> {
        return filter { element -> Bool in
            return element.value != nil
        }
    }

    public func replaceNil(with nilValue: Element.Wrapped) -> SharedSequence<SharingStrategy, Element.Wrapped> {
        return flatMap { element -> SharedSequence<SharingStrategy, Element.Wrapped> in
            if let value = element.value {
                return .just(value)
            } else {
                return .just(nilValue)
            }
        }
    }
}

public protocol BooleanType {
    var boolValue: Bool { get }
}

extension Bool: BooleanType {
    public var boolValue: Bool { return self }
}

/// Maps true to false and vice versa
extension Observable where Element: BooleanType {
    public func not() -> Observable<Bool> {
        return map { input in
            return !input.boolValue
        }
    }
}

extension Observable where Element: Equatable {
    public func ignore(value: Element) -> Observable<Element> {
        return filter { selfE -> Bool in
            return value != selfE
        }
    }
}

extension ObservableType where Element == Bool {
    /// Boolean not operator
    public func not() -> Observable<Bool> {
        return map(!)
    }
}

/// Maps true to false and vice versa
extension SharedSequenceConvertibleType where Element: BooleanType {
    public func not() -> SharedSequence<SharingStrategy, Bool> {
        return map { input in
            return !input.boolValue
        }
    }
}

extension SharedSequenceConvertibleType where Element: Equatable {
    public func ignore(value: Element) -> SharedSequence<SharingStrategy, Element> {
        return filter { selfE -> Bool in
            return value != selfE
        }
    }
}

extension SharedSequenceConvertibleType where Element == Bool {
    /// Boolean not operator
    public func not() -> SharedSequence<SharingStrategy, Bool> {
        return map(!)
    }
}

extension ObservableType where Element == Bool {
    public func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
}

extension SharedSequenceConvertibleType {
    public func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        return map { _ in }
    }
}
