import AVFoundation
import AppKit
import SitStandTimerCore
import UserNotifications

@MainActor
final class AlertService {
    private let center = UNUserNotificationCenter.current()
    private let synthesizer = AVSpeechSynthesizer()

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert])
        } catch {
            return false
        }
    }

    func announceStarted() {
        speak("Starting timer")
    }

    func announce(_ end: PhaseEnd) {
        switch end {
        case .work:
            speak("Please take a walk")
            notify(title: "Time to stand", body: "Break starting")
        case .break:
            speak("Work now")
            notify(title: "Break over", body: "Starting the next work block")
        }
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request, withCompletionHandler: nil)
    }
}
