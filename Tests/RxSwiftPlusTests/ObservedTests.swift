import Foundation
import RxRelay
import RxSwift
import RxSwiftPlus
import Testing

@Suite("Observed")
struct ObservedTests {
    /// Mirrors how a view model declares state: `count` is the value, `$count`
    /// the relay, and the wrapper itself is private synthesized storage.
    private final class Host: @unchecked Sendable {
        @Observed var count = 0

        var hasMaterializedRelay: Bool { _count.hasMaterializedRelay }
    }

    @Test("reads and writes stay on the inline slot until the projection is touched")
    func plainAccessDoesNotMaterializeTheRelay() {
        let host = Host()
        host.count = 7
        #expect(host.count == 7)
        #expect(!host.hasMaterializedRelay)
    }

    @Test("the projection is created once and seeded with the latest value")
    func projectionIsStableAndSeeded() {
        let host = Host()
        host.count = 3
        let relay = host.$count
        #expect(relay.value == 3)
        #expect(host.$count === relay)
        #expect(host.hasMaterializedRelay)
    }

    @Test("a subscriber receives the current value and every later write")
    func writesAfterProjectionReachSubscribers() {
        let host = Host()
        var received: [Int] = []
        let subscription = host.$count.subscribe(onNext: { received.append($0) })
        defer { subscription.dispose() }
        host.count = 1
        host.count = 2
        #expect(received == [0, 1, 2])
        #expect(host.count == 2)
        #expect(host.$count.value == 2)
    }

    @Test("binding into the projection updates the wrapped value")
    func bindingIntoProjectionUpdatesWrappedValue() {
        let host = Host()
        let subscription = Observable.just(9).bind(to: host.$count)
        defer { subscription.dispose() }
        #expect(host.count == 9)
    }

    @Test("wrapping an existing relay shares it")
    func initWithRelaySharesTheRelay() {
        let relay = BehaviorRelay(value: 1)
        let observed = Observed(relay: relay)
        observed.wrappedValue = 2
        #expect(relay.value == 2)
        #expect(observed.projectedValue === relay)
        #expect(observed.hasMaterializedRelay)
    }

    /// RxSwift's DEBUG tracker prints a "Reentrancy anomaly" for this: the
    /// write-back re-enters `BehaviorSubject.on` from inside the subscribe
    /// replay. That is the scenario under test, and an eagerly created relay
    /// prints the same warning; the assertion is that it completes.
    @Test("a subscriber may write the property back from inside the subscribe replay")
    func subscriberMayWriteBackSynchronously() {
        let host = Host()
        var received: [Int] = []
        let subscription = host.$count.subscribe(onNext: { value in
            received.append(value)
            if value == 0 {
                host.count = 1
            }
        })
        defer { subscription.dispose() }
        #expect(received == [0, 1])
    }

    @Test("concurrent readers, writers and projection agree on the final value")
    func concurrentAccessStaysConsistent() {
        let host = Host()
        // Writes are serialized so the relay's own grammar (no overlapping
        // `on` calls) holds, as it must for any `BehaviorRelay`; reads and the
        // materialization race freely against them, which is the storage's job.
        let writerQueue = DispatchQueue(label: "ObservedTests.writer")
        DispatchQueue.concurrentPerform(iterations: 256) { iteration in
            writerQueue.sync { host.count = iteration }
            _ = host.count
            if iteration.isMultiple(of: 64) {
                _ = host.$count
            }
        }
        #expect(host.count == host.$count.value)
        #expect(host.hasMaterializedRelay)
    }
}
