import RxSwift
import RxCocoa

extension ObservableType where Element == Void {
    public func subscribeOnMainActor<Object: AnyObject>(
        with object: Object,
        onNext: (@MainActor (Object) -> Void)?,
        onError: (@MainActor (Object, Swift.Error) -> Void)? = nil,
        onCompleted: (@MainActor (Object) -> Void)? = nil,
        onDisposed: (@MainActor (Object) -> Void)? = nil
    ) -> Disposable {
        subscribe(
            onNext: { [weak object] _ in
                guard let object else { return }
                Task { @MainActor in
                    onNext?(object)
                }
            },
            onError: { [weak object] error in
                guard let object else { return }
                Task { @MainActor in
                    onError?(object, error)
                }
            },
            onCompleted: { [weak object] in
                guard let object else { return }
                Task { @MainActor in
                    onCompleted?(object)
                }
            },
            onDisposed: { [weak object] in
                guard let object else { return }
                Task { @MainActor in
                    onDisposed?(object)
                }
            }
        )
    }

    public func subscribeOnMainActor(
        onNext: (@MainActor () -> Void)? = nil,
        onError: (@MainActor (Swift.Error) -> Void)? = nil,
        onCompleted: (@MainActor () -> Void)? = nil,
        onDisposed: (@MainActor () -> Void)? = nil
    ) -> Disposable {
        subscribe(
            onNext: { _ in
                Task { @MainActor in
                    onNext?()
                }
            },
            onError: { error in
                Task { @MainActor in
                    onError?(error)
                }
            },
            onCompleted: {
                Task { @MainActor in
                    onCompleted?()
                }
            },
            onDisposed: {
                Task { @MainActor in
                    onDisposed?()
                }
            }
        )
    }

    public func subscribeOnNextMainActor(_ onNext: @escaping (@MainActor () -> Void)) -> Disposable {
        subscribe(
            onNext: { _ in
                Task { @MainActor in
                    onNext()
                }
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        )
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == SignalSharingStrategy, Element == Void {
    public func emitOnMainActor<Object: AnyObject>(
        with object: Object,
        onNext: (@MainActor (Object) -> Void)?,
        onCompleted: (@MainActor (Object) -> Void)? = nil,
        onDisposed: (@MainActor (Object) -> Void)? = nil
    ) -> Disposable {
        emit(
            with: object,
            onNext: { (target: Object, element: Element) in
                Task { @MainActor in
                    onNext?(target)
                }
            },
            onCompleted: { target in
                Task { @MainActor in
                    onCompleted?(target)
                }
            },
            onDisposed: { target in
                Task { @MainActor in
                    onDisposed?(target)
                }
            }
        )
    }

    public func emitOnMainActor(
        onNext: (@MainActor () -> Void)?,
        onCompleted: (@MainActor () -> Void)? = nil,
        onDisposed: (@MainActor () -> Void)? = nil
    ) -> Disposable {
        emit(
            onNext: { _ in
                Task { @MainActor in
                    onNext?()
                }
            },
            onCompleted: {
                Task { @MainActor in
                    onCompleted?()
                }
            },
            onDisposed: {
                Task { @MainActor in
                    onDisposed?()
                }
            }
        )
    }

    public func emitOnNextMainActor(_ onNext: @escaping @MainActor () -> Void) -> Disposable {
        emitOnNext {
            Task { @MainActor in
                onNext()
            }
        }
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == SignalSharingStrategy {
    public func emitOnNextMainActor(_ onNext: @escaping (@MainActor (Element) -> Void)) -> Disposable {
        emitOnNext { element in
            Task { @MainActor in
                onNext(element)
            }
        }
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy {
    public func driveOnNextMainActor(_ onNext: @escaping (@MainActor (Element) -> Void)) -> Disposable {
        driveOnNext { element in
            Task { @MainActor in
                onNext(element)
            }
        }
    }
}

extension ObservableType {
    public func subscribeOnNextMainActor(_ onNext: @escaping (@MainActor (Element) -> Void)) -> Disposable {
        subscribeOnNext { element in
            Task { @MainActor in
                onNext(element)
            }
        }
    }
}
