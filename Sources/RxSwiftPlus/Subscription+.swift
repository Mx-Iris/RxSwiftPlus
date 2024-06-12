import Foundation
import RxSwift
import RxCocoa

extension ObservableType {
    public func bind<Root: AnyObject, Value>(on root: Root, to keyPath: ReferenceWritableKeyPath<Root, Value>) -> Disposable where Value == Element {
        subscribe(with: root) { $0[keyPath: keyPath] = $1 }
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy {
    public func drive<Root: AnyObject, Value>(on root: Root, to keyPath: ReferenceWritableKeyPath<Root, Value>) -> Disposable where Value == Element {
        drive(with: root) { $0[keyPath: keyPath] = $1 }
    }
}

extension SharedSequenceConvertibleType where SharingStrategy == SignalSharingStrategy {
    public func emit<Root: AnyObject, Value>(on root: Root, to keyPath: ReferenceWritableKeyPath<Root, Value>) -> Disposable where Value == Element {
        emit(with: root) { $0[keyPath: keyPath] = $1 }
    }
}
