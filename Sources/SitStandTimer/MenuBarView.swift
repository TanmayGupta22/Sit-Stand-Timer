import SitStandTimerCore
import SwiftUI

struct MenuBarView: View {
    @Bindable var model: TimerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.phaseLabel)
                .font(.headline)

            Text(model.formattedRemaining)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .frame(maxWidth: .infinity)

            if model.showsNotificationDeniedNote {
                Text("Notifications are off — you'll still hear the sound.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if model.isIdle {
                    Button("Start", action: model.start)
                } else if model.isPaused {
                    Button("Resume", action: model.resume)
                } else {
                    Button("Pause", action: model.pause)
                }

                if !model.isIdle {
                    Button("Skip", action: model.skip)
                    Button("Stop", action: model.stop)
                }
            }

            Stepper(value: $model.workMinutes, in: 1...120) {
                Text("Work: \(model.workMinutes) min")
            }
            Stepper(value: $model.breakMinutes, in: 1...30) {
                Text("Break: \(model.breakMinutes) min")
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

struct MenuBarLabel: View {
    var model: TimerModel

    var body: some View {
        Text(model.menuBarTitle)
    }
}
