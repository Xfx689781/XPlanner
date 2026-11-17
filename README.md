<p align="center">
  <img src="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" width="128" alt="XPlanner icon">
</p>

<h1 align="center">XPlanner</h1>

<p align="center">A geometric planner and log app: squares, circles and lines that turn each day into a shape you can see.</p>

<p align="center">
  <a href="https://github.com/Xfx689781/XPlanner/releases/latest"><b>⬇ Download the latest version (Android APK)</b></a>
</p>

---

## Download and install (Android)

1. On your phone, open the **[latest release](https://github.com/Xfx689781/XPlanner/releases/latest)**
2. Under **Assets**, download the APK that matches your phone:

   | File | For |
   | --- | --- |
   | `app-arm64-v8a-release.apk` | **Most phones: pick this one** (any recent Samsung, Pixel, Xiaomi, etc.) |
   | `app-armeabi-v7a-release.apk` | Very old 32-bit phones |
   | `app-x86_64-release.apk` | Android emulators on a computer |

3. Open the downloaded file. The first time, Android asks you to **allow installs from this source**. Allow it, go back and tap **Install**
4. If Play Protect shows a warning, tap **Install anyway**. This is normal for apps installed outside the Play Store

- Requires Android 7.0 or later
- To update, install the new APK over the old one. Your data is kept

### After installing (so reminders arrive on time)

- Allow **notifications** when the app first asks
- In the app, go to **Settings → Reminders** and turn on **Alarms & reminders** (exact alarms) and full-screen reminders as prompted
- On Samsung and similar phones: system Settings → Apps → XPlanner → Battery → **Unrestricted**. Otherwise battery saving may block reminders

## Features

- **Today**: a large circle at the top fills up as you complete today's tasks; below it are today's tasks and log entries
- **Tasks**: title, notes, date and time, three priority levels. Hollow square = open, filled square = done, thicker outline = higher priority
- **Reminders**: notifications at the set time, repeating never / daily / weekly, with several advance reminders per task. Reminders can ring like an alarm in full screen, and you can tap **Done** or **Snooze 10 min** right on the notification. Reminders still work after the phone restarts
- **Quick log**: one line with an automatic timestamp, grouped by day
- Light and dark themes; English, Simplified Chinese and Traditional Chinese

## Privacy

All data stays on your phone. Nothing is uploaded and the app never goes online. There are no accounts, ads or analytics.

## Build from source

Requires [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or later.

```bash
flutter pub get
flutter run -d windows                    # run on Windows
flutter build apk --release --split-per-abi
```

Release builds need your own signing key: create `android/key.properties` as described in `android/app/build.gradle.kts` (never commit it to git).

## Platforms

| Platform | Status |
| --- | --- |
| Android | ✅ Available |
| Windows | Runs from source; no installer published yet |
| iOS | Planned |
