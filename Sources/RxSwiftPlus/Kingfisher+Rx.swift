import RxCocoa
import RxSwift
import Kingfisher

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

extension KingfisherWrapper {
    public struct Rx<ImageView: KingfisherHasImageComponent> {
        private let wrapper: KingfisherWrapper<ImageView>

        init(_ base: KingfisherWrapper<ImageView>) {
            self.wrapper = base
        }

        public func image(
            placeholder: KFCrossPlatformImage? = nil,
            options: KingfisherOptionsInfo? = nil
        ) -> Binder<Resource?> {
            // `base.base` is the `Kingfisher` class' associated `ImageView`.
            return Binder(wrapper.base) { imageView, image in
                imageView.kf.setImage(
                    with: image,
                    placeholder: placeholder,
                    options: options
                )
            }
        }

        public func setImage(
            with source: Source?,
            placeholder: KFCrossPlatformImage? = nil,
            options: KingfisherOptionsInfo? = nil
        ) -> Single<KFCrossPlatformImage> {
            Single.create { [wrapper] single in
                let task = wrapper.setImage(
                    with: source,
                    placeholder: placeholder,
                    options: options,
                    completionHandler: { result in
                        switch result {
                        case let .success(value):
                            single(.success(value.image))
                        case let .failure(error):
                            single(.failure(error))
                        }
                    }
                )

                return Disposables.create { task?.cancel() }
            }
        }

        public func setImage(
            with resource: Resource?,
            placeholder: KFCrossPlatformImage? = nil,
            options: KingfisherOptionsInfo? = nil
        ) -> Single<KFCrossPlatformImage> {
            let source: Source?
            if let resource {
                source = Source.network(resource)
            } else {
                source = nil
            }
            return setImage(with: source, placeholder: placeholder, options: options)
        }
    }
}

extension KingfisherWrapper where Base: KingfisherHasImageComponent {
    public var rx: KingfisherWrapper.Rx<Base> {
        .init(self)
    }
}
