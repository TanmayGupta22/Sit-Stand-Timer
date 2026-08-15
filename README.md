# Sit-Stand Timer

A small macOS menu-bar timer that reminds you to stand up and walk, then start working again.

It lives in the top-right menu bar (no Dock icon). Defaults are 25 minutes of work and 2 minutes of break. When a phase ends, the Mac **speaks** a short line and shows a notification.

| When | What you hear |
| --- | --- |
| You press **Start** | “Starting timer” |
| Work time ends | “Please take a walk” |
| Break ends | “Work now” |

## Requirements

- A Mac running **macOS 14** or later
- [Xcode Command Line Tools](https://developer.apple.com/xcode/) (`swift` in Terminal). Full Xcode is not required.

Install Command Line Tools if needed:

```bash
xcode-select --install
```

## Mac settings you must change

The app cannot work fully until you allow it in System Settings. Do this on **each Mac** that runs it.

### 1. Allow notifications

The first time you start the app, macOS may ask for notification permission. Choose **Allow**.

If you missed that dialog, or banners do not appear:

1. Open **System Settings**
2. Go to **Notifications**
3. Find **SitStandTimer**
4. Turn **Allow Notifications** on
5. Set the alert style to **Banners** or **Alerts**

If notifications stay off, you will still hear the spoken reminder. The menu panel will show a note that notifications are off.

### 2. Allow the app to open (Privacy & Security)

This app is signed only for local use. On another Mac, Gatekeeper may block it the first time.

If you see *“SitStandTimer cannot be opened because it is from an unidentified developer”* (or *Apple cannot check it for malicious software*):

1. Open **System Settings**
2. Go to **Privacy & Security**
3. Scroll to the message about SitStandTimer
4. Click **Open Anyway**
5. Confirm **Open**

You can also Control-click the `.app` in Finder and choose **Open**.

### 3. Turn the volume up

Spoken alerts use the Mac’s speech voice. If volume is muted, or **System Settings → Sound → Output volume** is at zero, you will not hear “Please take a walk” or the other lines.

Also check **System Settings → Accessibility → Spoken Content** if speech never plays.

## Run it

```bash
git clone git@github.com:TanmayGupta22/Sit-Stand-Timer.git
cd Sit-Stand-Timer
chmod +x scripts/run.sh
./scripts/run.sh
```

Look in the **menu bar** (top right) for `25:00`. Click it.

- **Start** — begin a work interval
- **Pause / Resume** — freeze or continue the current interval
- **Skip** — jump work → break or break → work
- **Stop** — reset to idle
- Work minutes: 1–120
- Break minutes: 1–30 (new values apply to the **next** interval)

Quit from the same panel. The timer pauses if the Mac sleeps.

To run tests:

```bash
chmod +x scripts/test.sh
./scripts/test.sh
```

## License

Use and share freely for personal work-break reminders.
