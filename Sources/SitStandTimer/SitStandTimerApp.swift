import AppKit
import SitStandTimerCore
import SwiftUI

@main
struct SitStandTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: appDelegate.model)
        } label: {
            MenuBarLabel(model: appDelegate.model)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = TimerModel(settings: UserDefaultsSettingsStore(), clock: SystemClock())
    private let alerts = AlertService()
    private var sleepObserver: SleepObserver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let alerts = self.alerts
        model.onStarted = {
            alerts.announceStarted()
        }
        model.onPhaseEnded = { end in
            alerts.announce(end)
        }

        sleepObserver = SleepObserver { [weak self] in
            Task { @MainActor in
                self?.model.handleSleep()
            }
        }

        Task { [weak self] in
            guard let self else { return }
            let granted = await self.alerts.requestPermission()
            self.model.showsNotificationDeniedNote = !granted
        }

        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                self?.model.tick()
            }
        }
    }
}
