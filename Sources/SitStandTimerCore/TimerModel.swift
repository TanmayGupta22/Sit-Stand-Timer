import Foundation
import Observation

public enum TimerPhase: Equatable, Sendable {
    case idle
    case working
    case pausedWork
    case onBreak
    case pausedBreak
}

public enum PhaseEnd: Equatable, Sendable {
    case work
    case `break`
}

@Observable
public final class TimerModel {
    public private(set) var phase: TimerPhase = .idle
    public private(set) var remaining: TimeInterval
    public var showsNotificationDeniedNote = false
    public var onPhaseEnded: ((PhaseEnd) -> Void)?
    public var onStarted: (() -> Void)?

    public var workMinutes: Int {
        get { storedWorkMinutes }
        set {
            storedWorkMinutes = Self.clamp(newValue, lower: 1, upper: 120)
            settings.workMinutes = storedWorkMinutes
            if phase == .idle {
                remaining = Self.duration(minutes: storedWorkMinutes)
            }
        }
    }

    public var breakMinutes: Int {
        get { storedBreakMinutes }
        set {
            storedBreakMinutes = Self.clamp(newValue, lower: 1, upper: 30)
            settings.breakMinutes = storedBreakMinutes
        }
    }

    public var isIdle: Bool {
        phase == .idle
    }

    public var isPaused: Bool {
        switch phase {
        case .pausedWork, .pausedBreak:
            return true
        case .idle, .working, .onBreak:
            return false
        }
    }

    public var phaseLabel: String {
        switch phase {
        case .idle:
            return "Idle"
        case .working:
            return "Working"
        case .onBreak:
            return "Break"
        case .pausedWork, .pausedBreak:
            return "Paused"
        }
    }

    public var menuBarTitle: String {
        switch phase {
        case .idle, .working:
            return Self.format(remaining)
        case .onBreak:
            return "Break \(Self.format(remaining))"
        case .pausedWork, .pausedBreak:
            return "Paused"
        }
    }

    public var formattedRemaining: String {
        Self.format(remaining)
    }

    private let settings: SettingsStore
    private let clock: Clock
    private var endDate: Date?
    private var storedWorkMinutes: Int
    private var storedBreakMinutes: Int

    public init(settings: SettingsStore, clock: Clock) {
        self.settings = settings
        self.clock = clock
        let work = Self.clamp(settings.workMinutes, lower: 1, upper: 120)
        let breakLength = Self.clamp(settings.breakMinutes, lower: 1, upper: 30)
        storedWorkMinutes = work
        storedBreakMinutes = breakLength
        remaining = Self.duration(minutes: work)
    }

    public func start() {
        guard phase == .idle else { return }
        beginWork(announce: false)
        onStarted?()
    }

    public func pause() {
        switch phase {
        case .working:
            refreshRemaining()
            phase = .pausedWork
            endDate = nil
        case .onBreak:
            refreshRemaining()
            phase = .pausedBreak
            endDate = nil
        case .idle, .pausedWork, .pausedBreak:
            return
        }
    }

    public func resume() {
        switch phase {
        case .pausedWork:
            phase = .working
            endDate = clock.now.addingTimeInterval(remaining)
        case .pausedBreak:
            phase = .onBreak
            endDate = clock.now.addingTimeInterval(remaining)
        case .idle, .working, .onBreak:
            return
        }
    }

    public func skip() {
        switch phase {
        case .working, .pausedWork:
            beginBreak(announce: false)
        case .onBreak, .pausedBreak:
            beginWork(announce: false)
        case .idle:
            return
        }
    }

    public func stop() {
        phase = .idle
        endDate = nil
        remaining = Self.duration(minutes: storedWorkMinutes)
    }

    public func tick() {
        switch phase {
        case .working:
            refreshRemaining()
            if remaining <= 0 {
                beginBreak(announce: true)
            }
        case .onBreak:
            refreshRemaining()
            if remaining <= 0 {
                beginWork(announce: true)
            }
        case .idle, .pausedWork, .pausedBreak:
            return
        }
    }

    public func handleSleep() {
        pause()
    }

    private func beginWork(announce: Bool) {
        phase = .working
        remaining = Self.duration(minutes: storedWorkMinutes)
        endDate = clock.now.addingTimeInterval(remaining)
        if announce {
            onPhaseEnded?(.break)
        }
    }

    private func beginBreak(announce: Bool) {
        phase = .onBreak
        remaining = Self.duration(minutes: storedBreakMinutes)
        endDate = clock.now.addingTimeInterval(remaining)
        if announce {
            onPhaseEnded?(.work)
        }
    }

    private func refreshRemaining() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSince(clock.now))
    }

    private static func duration(minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }

    private static func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }

    private static func format(_ remaining: TimeInterval) -> String {
        let totalSeconds = max(0, Int(remaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
