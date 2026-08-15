import Foundation

public protocol Clock: AnyObject {
    var now: Date { get }
}

public final class SystemClock: Clock {
    public init() {}

    public var now: Date {
        Date()
    }
}

public final class TestClock: Clock {
    public var now: Date

    public init(_ now: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.now = now
    }

    public func advance(_ interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}
