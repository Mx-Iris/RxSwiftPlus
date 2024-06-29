import Foundation
import RxSwift
import RxCocoa

@propertyWrapper
public struct UserDefault<Element: Codable> {
    private let key: String
    private let defaultValue: Element
    private let suite: UserDefaults

    public var wrappedValue: Element {
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.setValue(data, forKey: key)
                suite.synchronize()
            }
        }
        get {
            guard let data = suite.data(forKey: key), let element = try? JSONDecoder().decode(Element.self, from: data) else {
                return defaultValue
            }
            return element
        }
    }

    public var projectedValue: Observable<Element> {
        suite.rx.observe(Data.self, key).compactMap { data in
            guard let data, let element = try? JSONDecoder().decode(Element.self, from: data) else {
                return defaultValue
            }
            return element
        }.startWith(wrappedValue).share()
    }

    public init(key: String, defaultValue: Element, suite: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.suite = suite
    }
}
