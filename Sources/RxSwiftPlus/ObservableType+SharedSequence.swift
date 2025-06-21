import RxSwift
import RxCocoa

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
}
