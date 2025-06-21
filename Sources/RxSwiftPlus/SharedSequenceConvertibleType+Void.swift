import RxSwift
import RxCocoa

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

extension SharedSequenceConvertibleType {
    public func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        return map { _ in }
    }
}
