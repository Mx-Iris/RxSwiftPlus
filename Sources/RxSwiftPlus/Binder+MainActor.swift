import RxSwift
import RxCocoa

extension Binder {
    public init<Target: AnyObject>(_ target: Target, scheduler: ImmediateSchedulerType = MainScheduler(), mainActorBinding: @MainActor @escaping (Target, Value) -> Void) {
        self.init(target, scheduler: scheduler, binding: { target, value in
            Task { @MainActor in
                mainActorBinding(target, value)
            }
        })
    }
}
