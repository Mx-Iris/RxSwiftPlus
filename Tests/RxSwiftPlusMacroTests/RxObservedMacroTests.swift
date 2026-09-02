import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import RxSwiftPlusMacroPlugin

final class RxObservedMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["RxObserved": RxObservedMacro.self]

    /// The test support elides the initializer that the `init` accessor
    /// consumes; the compiler keeps it, and `RxObservedTests` proves the
    /// initial value arrives in the storage.
    func testInitializedPropertyExpandsToAccessorsStorageAndProjection() {
        assertMacroExpansion(
            """
            final class Host {
                @RxObserved public private(set) var title: String = ""
            }
            """,
            expandedSource: """
            final class Host {
                public private(set) var title: String {
                    @storageRestrictions(initializes: _title)
                    init(initialValue) {
                        _title = RxSwiftPlus.RxObservedSlot(initialValue)
                    }
                    get {
                        _title.currentValue
                    }
                    set {
                        _title.value = newValue
                        let relay = _title.relay
                        relay?.accept(newValue)
                    }
                }

                private var _title: RxSwiftPlus.RxObservedSlot<String>

                public var $title: RxRelay.BehaviorRelay<String> {
                    if let relay = _title.relay {
                        return relay
                    }
                    let relay = RxRelay.BehaviorRelay(value: _title.value)
                    _title.relay = relay
                    return relay
                }
            }
            """,
            macros: macros
        )
    }

    func testOptionalWithoutInitializerDefaultsStorageToNil() {
        assertMacroExpansion(
            """
            final class Host {
                @RxObserved var text: String?
            }
            """,
            expandedSource: """
            final class Host {
                var text: String? {
                    @storageRestrictions(initializes: _text)
                    init(initialValue) {
                        _text = RxSwiftPlus.RxObservedSlot(initialValue)
                    }
                    get {
                        _text.currentValue
                    }
                    set {
                        _text.value = newValue
                        let relay = _text.relay
                        relay?.accept(newValue)
                    }
                }

                private var _text: RxSwiftPlus.RxObservedSlot<String?> = RxSwiftPlus.RxObservedSlot(nil)

                var $text: RxRelay.BehaviorRelay<String?> {
                    if let relay = _text.relay {
                        return relay
                    }
                    let relay = RxRelay.BehaviorRelay(value: _text.value)
                    _text.relay = relay
                    return relay
                }
            }
            """,
            macros: macros
        )
    }

    func testConstantIsRejected() {
        assertMacroExpansion(
            """
            final class Host {
                @RxObserved let title: String = ""
            }
            """,
            expandedSource: """
            final class Host {
                let title: String = ""
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@RxObserved requires 'var'; a 'let' cannot change and has nothing to observe", line: 2, column: 17),
            ],
            macros: macros
        )
    }

    func testMissingTypeAnnotationIsRejected() {
        assertMacroExpansion(
            """
            final class Host {
                @RxObserved var title = ""
            }
            """,
            expandedSource: """
            final class Host {
                var title = ""
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@RxObserved requires an explicit type annotation so the '$' projection can be typed", line: 2, column: 21),
            ],
            macros: macros
        )
    }

    func testStructHostIsRejected() {
        assertMacroExpansion(
            """
            struct Host {
                @RxObserved var title: String = ""
            }
            """,
            expandedSource: """
            struct Host {
                var title: String = ""
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@RxObserved can only be used inside a class or actor", line: 2, column: 5),
            ],
            macros: macros
        )
    }
}
