import RxSwift
import RxCocoa
import RxRelay

extension PublishSubject where Element == Void {
    public func onNext() {
        onNext(())
    }
}


