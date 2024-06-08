import Foundation
import RxSwift
import RxCocoa
import Defaults

@propertyWrapper
public struct UserDefault<Element: Codable> {
    private let key: Defaults.Key<AnyDefaultsSerializable<Element>>

    public var wrappedValue: Element {
        nonmutating set {
            Defaults[key] = AnyDefaultsSerializable(wrappedValue: newValue)
        }
        get {
            Defaults[key].wrappedValue
        }
    }

    public var projectedValue: ControlProperty<Element> {
        let observable = Defaults.publisher(key).asObservable().map(\.newValue.wrappedValue).startWith(wrappedValue)
        let observer = AnyObserver<Element> { event in
            switch event {
            case let .next(newValue):
                self.wrappedValue = newValue
            default:
                break
            }
        }
        return .init(values: observable, valueSink: observer)
    }

    public init(key: String, defaultValue: Element, suite: UserDefaults = .standard) {
        self.key = .init(key, default: AnyDefaultsSerializable(wrappedValue: defaultValue), suite: suite)
    }
}

struct AnyDefaultsSerializable<Element: Codable>: Codable, Defaults.Serializable {
    var wrappedValue: Element
}

import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    /// Returns an Observable<Output> representing the underlying
    /// Publisher. Upon subscription, the Publisher's sink pushes
    /// events into the Observable. Upon disposing of the subscription,
    /// the sink is cancelled.
    ///
    /// - returns: Observable<Output>
    func asObservable() -> Observable<Output> {
        Observable<Output>.create { observer in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        observer.onCompleted()
                    case let .failure(error):
                        observer.onError(error)
                    }
                },
                receiveValue: { value in
                    observer.onNext(value)
                }
            )

            return Disposables.create { cancellable.cancel() }
        }
    }
}
