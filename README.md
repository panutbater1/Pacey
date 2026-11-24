# Pacey

A safety drinking app that helps people pace their drinking during one night out, so they have fun without getting too drunk.

## Run it on your laptop

Pacey runs as a real app in a phone-shaped window, with real time and your data saved between launches. You need [Node.js](https://nodejs.org) (LTS).

### Quickest: from the Pacey folder

Open a terminal in this folder (the one with this README) and run:

```bash
npm start
```

The first time it sets itself up (about a minute), then the Pacey window opens.

### Type `pacey` anywhere

Run this once, in this folder:

```bash
npm install -g .
```

From then on, typing `pacey` in any terminal opens the app. Use `pacey --dev` for the testing buttons (Skip setup and Lock). On a Mac, if it says permission denied, run it with `sudo` in front.

See [`desktop/README.md`](desktop/README.md) for more.

## The prototype

`prototype/Main.dc.html` is the full clickable prototype: one 390 × 844 phone screen that holds the whole app flow. It's written in the Claude Design canvas format, so it opens in the Claude artifact viewer rather than as a plain web page. `prototype/canvas.json` is the canvas layout that goes with it.

### What it covers

- **First launch:** age gate with a required Terms and Privacy tick box, a 3-question quiz, a create-account step (Apple, Google or email, or continue without an account), the suggested plan, and a "How Pacey works" overview.
- **Home:** quick start presets, pace streak, tonight's plan with scroll-wheel pickers, Start my night. During a night: a timer and a "Logged tonight" list.
- **Tonight:**
  - During a night: the glass that fills, amount drunk and alcohol, pace countdown, water cup, last drink time, + Water, and + Drink with an arrow to switch drink type. Also Water first, drink-specific log animations and past-your-plan notifications.
  - The morning after: a check-in and a fix-up for anything you forgot to log.
  - Any other time: Getting ready (before-you-go checklist, tonight's reason, your usual plan, a tip from your history).
- **Nights:** a list of nights, plus Weeks and Months views with a calendar and stats. Each night opens its summary.
- **Night summary:** plan circles, how long the night lasted, total drunk and alcohol, pace, hour-by-hour bars and everything logged.
- **Settings:** profile and account, pace plan, quick start, drink types, drink sizes (ml or fl oz), reminders, emergency and safety, terms and conditions, data and privacy, about.
- **Lock screen and Dynamic Island:** lock screen widgets and a Live Activity that log drinks without opening the app, and a Dynamic Island with the pacer and drink count during a night.
- **Need help?** in the top bar during a night: call emergency services, send your location, get a ride home, signs someone needs urgent help.

### Prototype-only controls

These are for testing and are not part of the app:

- **Skip setup · prototype only** (top right during first launch) jumps straight to Home.
- **Lock** (top left during a night) previews the lock screen widgets and Live Activity.
- Both can be hidden with the **devSkip** setting in the prototype's Tweaks panel.
- The prototype runs time fast: one real second is one minute of the night.

## Other folders

- `design/` — the HTML mockups for the four v1 screens and the app's logo, the tilted glass (`LogoTilt.dc.html`).
- `docs/PACEY_BRIEF.md` — the original product brief.
- `docs/legal-text.json` — the Terms and conditions and Privacy policy text used in the prototype. It's a plain-English draft, not legal advice: have it reviewed by a lawyer before release.
- `docs/app-icon.png` — the app icon (1024 × 1024).

## Design

Dark charcoal background (`#1A1A1C`), grey cards (`#262628`), mint accent (`#6EE7C1`), sky blue for water (`#5CC8F5`), orange for "plan reached" (`#FF8A3D`) and red only for emergencies. Font: Outfit.

## Next

The native iPhone app (SwiftUI, iOS 17+) will be brought in line with this prototype.
