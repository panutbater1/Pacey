# Pacey 1.0

iPhone app (SwiftUI, iOS 17+) that helps people pace their drinking during one night out.

## Run it

1. Open `Pacey.xcodeproj` in Xcode.
2. Select the Pacey target → Signing & Capabilities → choose your team, and change the bundle identifier from `com.example.pacey`.
3. Pick your iPhone and press Run.

Calling, Messages and notifications only work fully on a real iPhone, not the simulator.

Debug builds show a **Skip setup · debug only** button during onboarding. It is compiled out of Release (App Store) builds.

## What's in it

- **First launch only:** age gate, a 3-question quiz, the suggested plan and a "How Pacey works" overview. The quiz can't be retaken; the average is changed later in Settings › Pace plan.
- **Home:** quick start chips (drinks, home-by time and transport in one tap), pace streak, tonight's plan with scroll-wheel pickers, Start my night. During a night: a timer and an expandable "Logged tonight" list.
- **Tonight (Drink mode):** glass that fills, amount drunk and alcohol, pace countdown, water cup, last drink time, + Water, + Drink with an arrow to switch drink type, Water first, drink-specific log animations, kind notifications past the plan.
- **Last night** (when no night is running): morning check-in and a fix-up for drinks or water you forgot to log.
- **Nights:** every finished night by date, each opening its summary.
- **Night summary:** plan circles, how long the night lasted, total drunk and alcohol, estimated blood alcohol (range and curve, clearly marked as an estimate), pace in minutes between drinks, hour-by-hour bars, and everything logged with sizes.
- **Settings:** Profile (name, trusted friend, weight, body type), Pace plan, Quick start, Drink type (several), Drink sizes (ml or fl oz), Reminders, Emergency and safety, Data and privacy, About.
- **Need help?** only shows in the top bar during a night; it is always reachable from Settings › Emergency and safety.

## Layout

- `Pacey/Core/PaceyCore.swift` — pure logic (drink types and sizes, preferences, quiz, pacing, blood alcohol estimate). Foundation only, so it can be unit tested anywhere.
- `Pacey/Core/AppSettings.swift` — saves preferences on the phone.
- `Pacey/Models.swift` — SwiftData models (`Night`, `LogEntry`) and per-night totals, records and estimate.
- `Pacey/Reminders.swift` — local notifications, shown as banners even while the app is open.
- `Pacey/DesignSystem.swift` — colours, Outfit font, buttons, cards, top bar, steppers, wheel sheets.
- `Pacey/Support.swift` — legal age and emergency number by region, taxi / call / message actions, location.
- `Pacey/Views/` — onboarding, Home, Drink mode, log animations, Last night, Nights, Summary, Settings, Need help.
- `design/` — the HTML mockups used as reference.

## Rules worth keeping

- Suggested limit = never above 4 and never above the person's average. Quick starts can't go above the average.
- Planned drinks are spread evenly between "Start my night" and home-by, never closer than 30 minutes.
- Blood alcohol is a Widmark-style estimate shown as a range, with no legal-limit line and no "safe to drive" wording.
- Before release: link Terms and conditions and Privacy policy in Settings › About (marked TODO).
