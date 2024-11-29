import RxSwift
import Kingfisher

extension Reactive where Base == KingfisherManager {
    public func retrieveImage(with source: Source,
                              options: KingfisherOptionsInfo? = nil) -> Single<KFCrossPlatformImage> {
        return Single.create { [base] single in
            let task = base.retrieveImage(with: source,
                                          options: options) { result in
                switch result {
                case .success(let value):
                    single(.success(value.image))
                case .failure(let error):
                    single(.failure(error))
                }
            }

            return Disposables.create { task?.cancel() }
        }
    }
    
    public func retrieveImage(with resource: Resource,
                              options: KingfisherOptionsInfo? = nil) -> Single<KFCrossPlatformImage> {
        let source = Source.network(resource)
        return retrieveImage(with: source, options: options)
    }

}

extension KingfisherManager: @retroactive ReactiveCompatible {
    public var rx: Reactive<KingfisherManager> {
        get { return Reactive(self) }
        set { }
    }
}
