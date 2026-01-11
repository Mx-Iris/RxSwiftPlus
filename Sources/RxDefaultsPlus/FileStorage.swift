import Foundation
import RxSwift
import RxCocoa

@propertyWrapper
public final class FileStorage<T: Codable> {
    private let key: String
    private let directory: FileManager.SearchPathDirectory
    private let defaultValue: T
    private let fileManager = FileManager.default

    private var cachedValue: T?

    private let queue = DispatchQueue(label: "com.RxSwiftPlus.FileStorage.queue", attributes: .concurrent)

    private let relay = PublishRelay<T>()

    public init(wrappedValue: T, _ key: String, directory: FileManager.SearchPathDirectory = .documentDirectory) {
        self.defaultValue = wrappedValue
        self.key = key
        self.directory = directory
    }

    public var wrappedValue: T {
        get {
            var memResult: T?
            queue.sync {
                memResult = cachedValue
            }
            if let memResult { return memResult }

            return queue.sync(flags: .barrier) {
                if let val = cachedValue { return val }
                let loaded = loadFromDisk()
                cachedValue = loaded
                return loaded
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }

                self.cachedValue = newValue

                self.relay.accept(newValue)

                self.saveToDisk(newValue)
            }
        }
    }

    public var projectedValue: Observable<T> {
        return Observable.deferred { [weak self] in
            guard let self = self else { return .empty() }
            return self.relay.asObservable().startWith(self.wrappedValue)
        }
    }

    private func fileURL() throws -> URL {
        let urls = fileManager.urls(for: directory, in: .userDomainMask)
        guard let baseURL = urls.first else {
            throw NSError(domain: "FileStorageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find directory"])
        }
        let folderURL = baseURL.appendingPathComponent("AppStorage", isDirectory: true)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        return folderURL.appendingPathComponent("\(key).json")
    }

    private func loadFromDisk() -> T {
        do {
            let url = try fileURL()
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return defaultValue
        }
    }

    private func saveToDisk(_ value: T) {
        do {
            let url = try fileURL()
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            #if DEBUG
            print("[FileStorage] Write error: \(error)")
            #endif
        }
    }
}
