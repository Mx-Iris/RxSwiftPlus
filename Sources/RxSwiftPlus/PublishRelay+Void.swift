import RxSwift
import RxCocoa
import RxRelay

extension PublishRelay where Element == Void {
    public func accept() {
        accept(())
    }
}
