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

extension ObservableType {
    public func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
}





