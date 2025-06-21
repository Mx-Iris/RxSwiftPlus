import RxSwift
import RxCocoa

extension PrimitiveSequenceType where Trait == SingleTrait {
    public typealias SingleObserver = (SingleEvent<Element>) -> Void

    /// Creates an observable sequence from a specified subscribe method implementation.
    ///
    /// - seealso: [create operator on reactivex.io](http://reactivex.io/documentation/operators/create.html)
    ///
    /// - parameter subscribe: Implementation of the resulting observable sequence's `subscribe` method.
    /// - returns: The observable sequence with the specified implementation for the `subscribe` method.
    public static func create(mainActorSubscribe: @MainActor @escaping (@escaping SingleObserver) -> Disposable) -> Single<Element> {
        create(subscribe: { observer in
            let task = Task { @MainActor in
                mainActorSubscribe(observer)
            }
            return Disposables.create {
                task.cancel()
            }
        })
    }
}
