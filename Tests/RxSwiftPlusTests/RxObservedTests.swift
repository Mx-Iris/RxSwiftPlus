import Foundation
import RxRelay
import RxSwift
import RxSwiftPlus
import RxSwiftPlusMacro
import Testing

@Suite("RxObserved")
struct RxObservedTests {
    /// Mirrors how a view model declares state. `count` has an initializer,
    /// `title` is an optional without one, `seed` is assigned in `init`.
    private final class Host: @unchecked Sendable {
        @RxObserved var count: Int = 0
        @RxObserved private(set) var title: String?
        @RxObserved var seed: String

        var countHasMaterializedRelay: Bool { _count.hasMaterializedRelay }
        var titleHasMaterializedRelay: Bool { _title.hasMaterializedRelay }

        init(seed: String) {
            self.seed = seed
        }

        func rename(_ newTitle: String?) {
            title = newTitle
        }
    }

    @Test("reads and writes stay on the inline slot until the projection is touched")
    func plainAccessDoesNotMaterializeTheRelay() {
        let host = Host(seed: "seed")
        host.count = 7
        #expect(host.count == 7)
        #expect(!host.countHasMaterializedRelay)
    }

    @Test("an optional without an initializer starts at nil and needs no assignment in init")
    func optionalWithoutInitializerStartsNil() {
        let host = Host(seed: "seed")
        #expect(host.title == nil)
        host.rename("Renamed")
        #expect(host.title == "Renamed")
        #expect(!host.titleHasMaterializedRelay)
    }

    @Test("a value assigned in init reaches the storage through the init accessor")
    func initializerAssignmentGoesThroughTheInitAccessor() {
        let host = Host(seed: "seed")
        #expect(host.seed == "seed")
        #expect(host.$seed.value == "seed")
    }

    @Test("the projection is created once and seeded with the latest value")
    func projectionIsStableAndSeeded() {
        let host = Host(seed: "seed")
        host.count = 3
        let relay = host.$count
        #expect(relay.value == 3)
        #expect(host.$count === relay)
        #expect(host.countHasMaterializedRelay)
    }

    @Test("a subscriber receives the current value and every later write")
    func writesAfterProjectionReachSubscribers() {
        let host = Host(seed: "seed")
        var received: [Int] = []
        let subscription = host.$count.subscribe(onNext: { received.append($0) })
        defer { subscription.dispose() }
        host.count = 1
        host.count = 2
        #expect(received == [0, 1, 2])
        #expect(host.count == 2)
    }

    @Test("binding into the projection updates the property")
    func bindingIntoProjectionUpdatesTheProperty() {
        let host = Host(seed: "seed")
        let subscription = Observable.just(9).bind(to: host.$count)
        defer { subscription.dispose() }
        #expect(host.count == 9)
    }

    @Test("a subscriber may read the property and write it back from inside the subscribe replay")
    func subscriberMayReadAndWriteBackDuringReplay() {
        let host = Host(seed: "seed")
        var received: [Int] = []
        let subscription = host.$count.subscribe(onNext: { value in
            // Reading `count` here would trip exclusivity enforcement if the
            // setter still held an access to the slot while dispatching.
            received.append(host.count)
            if value == 0 {
                host.count = 1
            }
        })
        defer { subscription.dispose() }
        #expect(received == [0, 1])
    }

    @Test("a subscriber reading the property during a write sees the new value")
    func subscriberReadingDuringWriteSeesTheNewValue() {
        let host = Host(seed: "seed")
        var observed: [Int] = []
        let subscription = host.$count.subscribe(onNext: { _ in observed.append(host.count) })
        defer { subscription.dispose() }
        host.count = 5
        #expect(observed == [0, 5])
    }
}
