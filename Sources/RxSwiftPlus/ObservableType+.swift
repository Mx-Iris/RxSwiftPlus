import RxSwift
import RxCocoa

extension ObservableType where Element == Void {
    public func subscribe<Object: AnyObject>(
        with object: Object,
        onNext: ((Object) -> Void)?,
        onError: ((Object, Swift.Error) -> Void)? = nil,
        onCompleted: ((Object) -> Void)? = nil,
        onDisposed: ((Object) -> Void)? = nil
    ) -> Disposable {
        subscribe(
            onNext: { [weak object] _ in
                guard let object else { return }
                onNext?(object)
            },
            onError: { [weak object] in
                guard let object else { return }
                onError?(object, $0)
            },
            onCompleted: { [weak object] in
                guard let object else { return }
                onCompleted?(object)
            },
            onDisposed: { [weak object] in
                guard let object else { return }
                onDisposed?(object)
            }
        )
    }

    public func subscribe(
        onNext: (() -> Void)? = nil,
        onError: ((Swift.Error) -> Void)? = nil,
        onCompleted: (() -> Void)? = nil,
        onDisposed: (() -> Void)? = nil
    ) -> Disposable {
        subscribe(
            onNext: { _ in
                onNext?()
            },
            onError: onError,
            onCompleted: onCompleted,
            onDisposed: onDisposed
        )
    }

    public func subscribeOnNext(_ onNext: @escaping (() -> Void)) -> Disposable {
        subscribe(
            onNext: { _ in
                onNext()
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        )
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy, Element == Void {
    public func drive<Object: AnyObject>(
        with object: Object,
        onNext: ((Object) -> Void)?,
        onCompleted: ((Object) -> Void)? = nil,
        onDisposed: ((Object) -> Void)? = nil
    ) -> Disposable {
        drive(
            with: object,
            onNext: { (target: Object, element: Element) in
                onNext?(target)
            },
            onCompleted: onCompleted,
            onDisposed: onDisposed
        )
    }

    public func drive(
        onNext: (() -> Void)?,
        onCompleted: (() -> Void)? = nil,
        onDisposed: (() -> Void)? = nil
    ) -> Disposable {
        drive(
            onNext: { _ in
                onNext?()
            },
            onCompleted: onCompleted,
            onDisposed: onDisposed
        )
    }

    public func driveOnNext(_ onNext: @escaping (() -> Void)) -> Disposable {
        drive(
            onNext: { _ in
                onNext()
            },
            onCompleted: nil,
            onDisposed: nil
        )
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == SignalSharingStrategy, Element == Void {
    public func emit<Object: AnyObject>(
        with object: Object,
        onNext: ((Object) -> Void)?,
        onCompleted: ((Object) -> Void)? = nil,
        onDisposed: ((Object) -> Void)? = nil
    ) -> Disposable {
        emit(
            with: object,
            onNext: { (target: Object, element: Element) in
                onNext?(target)
            },
            onCompleted: onCompleted,
            onDisposed: onDisposed
        )
    }

    public func emit(
        onNext: (() -> Void)?,
        onCompleted: (() -> Void)? = nil,
        onDisposed: (() -> Void)? = nil
    ) -> Disposable {
        emit(
            onNext: { _ in
                onNext?()
            },
            onCompleted: onCompleted,
            onDisposed: onDisposed
        )
    }

    public func emitOnNext(_ onNext: @escaping () -> Void) -> Disposable {
        emit(
            onNext: { _ in
                onNext()
            },
            onCompleted: nil,
            onDisposed: nil
        )
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == SignalSharingStrategy {
    public func emitOnNext(_ onNext: @escaping (Element) -> Void) -> Disposable {
        emit(onNext: onNext, onCompleted: nil, onDisposed: nil)
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy {
    public func driveOnNext(_ onNext: @escaping ((Element) -> Void)) -> Disposable {
        drive(onNext: onNext, onCompleted: nil, onDisposed: nil)
    }
}

extension ObservableType {
    public func subscribeOnNext(_ onNext: @escaping ((Element) -> Void)) -> Disposable {
        subscribe(onNext: onNext, onError: nil, onCompleted: nil, onDisposed: nil)
    }
}

extension ObservableType where Element: EventConvertible {
    public func filterCompletion() -> Observable<Element> {
        return filter { !$0.event.isCompleted }
    }
}

extension ObservableType {
    public func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { error in
            assertionFailure("Error \(error)")
            return Driver.empty()
        }
    }

    public func asSignalOnErrorJustComplete() -> Signal<Element> {
        return asSignal { error in
            assertionFailure("Error \(error)")
            return Signal.empty()
        }
    }

    public func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
}
