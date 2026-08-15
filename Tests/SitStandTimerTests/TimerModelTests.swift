import Foundation
import SitStandTimerCore

enum ExpectationFailure: Error, CustomStringConvertible {
    case mismatch(String)

    var description: String {
        switch self {
        case let .mismatch(message):
            return message
        }
    }
}

func expectEqual<T: Equatable>(
    _ actual: T,
    _ expected: T,
    file: String = #fileID,
    line: Int = #line
) throws {
    if actual != expected {
        throw ExpectationFailure.mismatch("\(file):\(line) expected \(expected), got \(actual)")
    }
}

func expectTrue(_ value: Bool, file: String = #fileID, line: Int = #line) throws {
    if !value {
        throw ExpectationFailure.mismatch("\(file):\(line) expected true")
    }
}

private func makeModel(
    work: Int = 25,
    breakMinutes: Int = 2,
    clock: TestClock = TestClock()
) -> (TimerModel, TestClock, InMemorySettingsStore) {
    let store = InMemorySettingsStore(workMinutes: work, breakMinutes: breakMinutes)
    let model = TimerModel(settings: store, clock: clock)
    return (model, clock, store)
}

func testStartsIdleWithWorkDuration() throws {
    let (model, _, _) = makeModel()

    try expectEqual(model.phase, .idle)
    try expectEqual(model.remaining, TimeInterval(25 * 60))
    try expectEqual(model.menuBarTitle, "25:00")
    try expectEqual(model.phaseLabel, "Idle")
}

func testStartBeginsWork() throws {
    let (model, _, _) = makeModel()

    model.start()

    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, TimeInterval(25 * 60))
    try expectEqual(model.menuBarTitle, "25:00")
    try expectEqual(model.phaseLabel, "Working")
}

func testStartAnnouncesOnceFromIdle() throws {
    let (model, _, _) = makeModel()
    var started = 0
    model.onStarted = { started += 1 }

    model.start()
    try expectEqual(started, 1)

    model.start()
    try expectEqual(started, 1)
}

func testResumeSkipAndBreakEndDoNotAnnounceStart() throws {
    let (model, clock, _) = makeModel()
    var started = 0
    model.onStarted = { started += 1 }

    model.start()
    try expectEqual(started, 1)

    model.pause()
    model.resume()
    try expectEqual(started, 1)

    model.skip()
    model.skip()
    try expectEqual(started, 1)

    clock.advance(25 * 60)
    model.tick()
    clock.advance(2 * 60)
    model.tick()
    try expectEqual(started, 1)
}

func testStopThenStartAnnouncesAgain() throws {
    let (model, _, _) = makeModel()
    var started = 0
    model.onStarted = { started += 1 }

    model.start()
    model.stop()
    model.start()

    try expectEqual(started, 2)
}

func testTickReducesRemainingWhileWorking() throws {
    let (model, clock, _) = makeModel()
    model.start()

    clock.advance(12)
    model.tick()

    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, TimeInterval(25 * 60 - 12))
    try expectEqual(model.menuBarTitle, "24:48")
}

func testWorkEndingStartsBreak() throws {
    let (model, clock, _) = makeModel()
    var ended: [PhaseEnd] = []
    model.onPhaseEnded = { ended.append($0) }
    model.start()

    clock.advance(25 * 60)
    model.tick()

    try expectEqual(model.phase, .onBreak)
    try expectEqual(model.remaining, TimeInterval(2 * 60))
    try expectEqual(model.menuBarTitle, "Break 2:00")
    try expectEqual(model.phaseLabel, "Break")
    try expectEqual(ended, [.work])
}

func testBreakEndingStartsNextWork() throws {
    let (model, clock, _) = makeModel()
    var ended: [PhaseEnd] = []
    model.onPhaseEnded = { ended.append($0) }
    model.start()
    clock.advance(25 * 60)
    model.tick()

    clock.advance(2 * 60)
    model.tick()

    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, TimeInterval(25 * 60))
    try expectEqual(model.menuBarTitle, "25:00")
    try expectEqual(ended, [.work, .break])
}

func testPauseFreezesRemaining() throws {
    let (model, clock, _) = makeModel()
    model.start()
    clock.advance(10)
    model.tick()

    model.pause()
    clock.advance(30)
    model.tick()

    try expectEqual(model.phase, .pausedWork)
    try expectEqual(model.remaining, TimeInterval(25 * 60 - 10))
    try expectEqual(model.menuBarTitle, "Paused")
    try expectEqual(model.phaseLabel, "Paused")
}

func testResumeContinuesFromFrozenRemaining() throws {
    let (model, clock, _) = makeModel()
    model.start()
    clock.advance(10)
    model.tick()
    model.pause()
    clock.advance(30)

    model.resume()
    clock.advance(5)
    model.tick()

    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, TimeInterval(25 * 60 - 15))
}

func testPauseAndResumeDuringBreak() throws {
    let (model, clock, _) = makeModel()
    model.start()
    clock.advance(25 * 60)
    model.tick()

    model.pause()
    try expectEqual(model.phase, .pausedBreak)

    clock.advance(20)
    model.tick()
    try expectEqual(model.remaining, TimeInterval(2 * 60))

    model.resume()
    clock.advance(15)
    model.tick()
    try expectEqual(model.phase, .onBreak)
    try expectEqual(model.remaining, TimeInterval(2 * 60 - 15))
}

func testSkipFromWorkJumpsToBreak() throws {
    let (model, clock, _) = makeModel()
    var ended: [PhaseEnd] = []
    model.onPhaseEnded = { ended.append($0) }
    model.start()
    clock.advance(8)
    model.tick()

    model.skip()

    try expectEqual(model.phase, .onBreak)
    try expectEqual(model.remaining, TimeInterval(2 * 60))
    try expectTrue(ended.isEmpty)
}

func testSkipFromBreakJumpsToWork() throws {
    let (model, _, _) = makeModel()
    var ended: [PhaseEnd] = []
    model.onPhaseEnded = { ended.append($0) }
    model.start()
    model.skip()

    model.skip()

    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, TimeInterval(25 * 60))
    try expectTrue(ended.isEmpty)
}

func testSkipFromPausedWorkJumpsToBreak() throws {
    let (model, _, _) = makeModel()
    model.start()
    model.pause()

    model.skip()

    try expectEqual(model.phase, .onBreak)
    try expectEqual(model.remaining, TimeInterval(2 * 60))
}

func testStopReturnsToIdle() throws {
    let (model, clock, _) = makeModel()
    model.start()
    clock.advance(40)
    model.tick()

    model.stop()

    try expectEqual(model.phase, .idle)
    try expectEqual(model.remaining, TimeInterval(25 * 60))
    try expectEqual(model.menuBarTitle, "25:00")
    try expectEqual(model.phaseLabel, "Idle")
}

func testDurationEditDoesNotResetCurrentInterval() throws {
    let (model, clock, store) = makeModel()
    model.start()
    clock.advance(10)
    model.tick()

    model.workMinutes = 40

    try expectEqual(model.remaining, TimeInterval(25 * 60 - 10))
    try expectEqual(store.workMinutes, 40)
}

func testNextWorkIntervalUsesEditedDuration() throws {
    let (model, _, _) = makeModel()
    model.start()
    model.workMinutes = 40

    model.skip()
    model.skip()

    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, TimeInterval(40 * 60))
    try expectEqual(model.menuBarTitle, "40:00")
}

func testMinutesAreClamped() throws {
    let (model, _, store) = makeModel()

    model.workMinutes = 0
    try expectEqual(model.workMinutes, 1)
    model.workMinutes = 200
    try expectEqual(model.workMinutes, 120)

    model.breakMinutes = 0
    try expectEqual(model.breakMinutes, 1)
    model.breakMinutes = 99
    try expectEqual(model.breakMinutes, 30)

    try expectEqual(store.workMinutes, 120)
    try expectEqual(store.breakMinutes, 30)
}

func testHandleSleepPausesWork() throws {
    let (model, _, _) = makeModel()
    model.start()

    model.handleSleep()

    try expectEqual(model.phase, .pausedWork)
}

func testHandleSleepPausesBreak() throws {
    let (model, _, _) = makeModel()
    model.start()
    model.skip()

    model.handleSleep()

    try expectEqual(model.phase, .pausedBreak)
}

func testHandleSleepIsNoOpWhenNotRunning() throws {
    let (model, _, _) = makeModel()
    model.handleSleep()
    try expectEqual(model.phase, .idle)

    model.start()
    model.pause()
    model.handleSleep()
    try expectEqual(model.phase, .pausedWork)
}

func testStartAndPauseAreNoOpsInWrongPhase() throws {
    let (model, clock, _) = makeModel()
    model.start()
    clock.advance(10)
    model.tick()
    let remaining = model.remaining

    model.start()
    try expectEqual(model.phase, .working)
    try expectEqual(model.remaining, remaining)

    model.pause()
    model.pause()
    try expectEqual(model.phase, .pausedWork)
}

@main
struct TimerModelTestRunner {
    static func main() {
        let tests: [(String, () throws -> Void)] = [
            ("starts idle with work duration", testStartsIdleWithWorkDuration),
            ("start begins work", testStartBeginsWork),
            ("start announces once from idle", testStartAnnouncesOnceFromIdle),
            ("resume skip and break end do not announce start", testResumeSkipAndBreakEndDoNotAnnounceStart),
            ("stop then start announces again", testStopThenStartAnnouncesAgain),
            ("tick reduces remaining while working", testTickReducesRemainingWhileWorking),
            ("work ending starts break", testWorkEndingStartsBreak),
            ("break ending starts next work", testBreakEndingStartsNextWork),
            ("pause freezes remaining", testPauseFreezesRemaining),
            ("resume continues from frozen remaining", testResumeContinuesFromFrozenRemaining),
            ("pause and resume during break", testPauseAndResumeDuringBreak),
            ("skip from work jumps to break", testSkipFromWorkJumpsToBreak),
            ("skip from break jumps to work", testSkipFromBreakJumpsToWork),
            ("skip from paused work jumps to break", testSkipFromPausedWorkJumpsToBreak),
            ("stop returns to idle", testStopReturnsToIdle),
            ("duration edit does not reset current interval", testDurationEditDoesNotResetCurrentInterval),
            ("next work interval uses edited duration", testNextWorkIntervalUsesEditedDuration),
            ("minutes are clamped", testMinutesAreClamped),
            ("handleSleep pauses work", testHandleSleepPausesWork),
            ("handleSleep pauses break", testHandleSleepPausesBreak),
            ("handleSleep is a no-op when not running", testHandleSleepIsNoOpWhenNotRunning),
            ("start and pause are no-ops in the wrong phase", testStartAndPauseAreNoOpsInWrongPhase),
        ]

        var failed = 0
        for (name, test) in tests {
            do {
                try test()
                print("PASS \(name)")
            } catch {
                failed += 1
                print("FAIL \(name): \(error)")
            }
        }

        print("\(tests.count - failed) passed, \(failed) failed, \(tests.count) total")
        if failed > 0 {
            exit(1)
        }
    }
}
