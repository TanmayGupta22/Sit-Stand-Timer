import Foundation

public protocol SettingsStore: AnyObject {
    var workMinutes: Int { get set }
    var breakMinutes: Int { get set }
}

public final class InMemorySettingsStore: SettingsStore {
    public var workMinutes: Int
    public var breakMinutes: Int

    public init(workMinutes: Int = 25, breakMinutes: Int = 2) {
        self.workMinutes = workMinutes
        self.breakMinutes = breakMinutes
    }
}

public final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    private let workKey = "workMinutes"
    private let breakKey = "breakMinutes"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var workMinutes: Int {
        get {
            if defaults.object(forKey: workKey) == nil {
                return 25
            }
            return defaults.integer(forKey: workKey)
        }
        set {
            defaults.set(newValue, forKey: workKey)
        }
    }

    public var breakMinutes: Int {
        get {
            if defaults.object(forKey: breakKey) == nil {
                return 2
            }
            return defaults.integer(forKey: breakKey)
        }
        set {
            defaults.set(newValue, forKey: breakKey)
        }
    }
}
