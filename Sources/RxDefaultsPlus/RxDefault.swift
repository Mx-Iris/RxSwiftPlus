import Foundation.NSUserDefaults
import RxSwift
import RxCocoa

@propertyWrapper
public final class UserDefault<Element: Codable> {
    public let key: String
    public let suite: UserDefaults
    public let defaultWrappedValue: Element

    public var wrappedValue: Element {
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.setValue(data, forKey: key)
            }
        }
        get {
            guard let data = suite.data(forKey: key), let wrappedValue = try? JSONDecoder().decode(Element.self, from: data) else {
                return defaultWrappedValue
            }

            return wrappedValue
        }
    }

    public var projectedValue: Observable<Element> {
        let defaultValue = defaultWrappedValue
        return suite.rx.observe(Data.self, key).compactMap { data in
            guard let data, let element = try? JSONDecoder().decode(Element.self, from: data) else {
                return defaultValue
            }
            return element
        }.startWith(wrappedValue).share()
    }

    public convenience init(key: String, defaultValue: Element, suite: UserDefaults = .standard) {
        self.init(wrappedValue: defaultValue, key: key, suite: suite)
    }

    public init(wrappedValue: Element, key: String, suite: UserDefaults = .standard) {
        self.key = key
        self.suite = suite
        self.defaultWrappedValue = wrappedValue
    }
}
