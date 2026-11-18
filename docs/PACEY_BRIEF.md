# Pacey — handoff brief for Claude Code

Paste this whole file into Claude Code (or drop it into the project folder), together with the `design/` folder from `pacey-handoff.zip`. Then ask: **"Read PACEY_BRIEF.md and the design files, then build version 1.0 of Pacey as an iPhone app in SwiftUI."**

---

## 1. What Pacey is

- An iPhone app that helps people **pace their drinking during one night out**, so they have fun without getting too drunk.
- It is **short-term pacing**, not a long-term "quit drinking" app.
- Earlier working name: "Shot o clock". Final name: **Pacey**.
- Tone: friendly, calm, never judgmental, and **never encourages drinking more**. It is about pacing and safety.

## 2. Positioning rules (important for App Store review)

- Say "Plan your night", not "tolerance".
- Say "You've reached your plan", not "shots you can still have".
- No drink-count leaderboards or anything that rewards drinking more. (Pace leaderboards are a later, optional idea.)
- Safety features are **always free**.
- Include an **age gate** at first launch (legal drinking age, e.g. 18+/21+ depending on region) and a disclaimer: Pacey is not medical advice and can't measure blood alcohol.
- Include a **"Need help?"** screen from day one.

## 3. Version 1.0 scope

**In v1:**
1. Age gate + short disclaimer on first launch.
2. **Home** — "Going out tonight?": set a drink plan (number of drinks), a "home by" time and how you're getting home, then **Start my night**.
3. **Drink mode** — a glass that fills as you log drinks, a countdown to when your next drink fits your plan, + Drink and + Water buttons, water count, time since last drink, End night button, ride-home and Need help buttons. When you reach your plan the glass turns orange and the message says "You've reached your plan — switch to water from here".
4. **Night summary** — "You stuck to your plan" (or a kind message if not), drinks, water, pace, an hour-by-hour chart, a "Getting home? Don't drive tonight" card with Book a taxi, and Done.
5. **Need help?** — big Call emergency services button (uses local number), Send my location to a friend, Get a ride home, signs someone needs urgent help, and what to do while waiting.
6. Gentle local notifications (e.g. "Water time", "Your next drink fits your plan now").
7. Store nights locally on the phone (no account needed for v1).

**Later (v2+), not in v1:** friends / group nights, invites and check-in messages ("Water round?", "You good?"), monthly stats calendar, widgets, Dynamic Island / Live Activity, Back Tap quick logging, paid features.

## 4. Tech direction

- **Native iPhone app in SwiftUI** (native is needed later for widgets, Live Activities / Dynamic Island and Back Tap).
- Local storage (SwiftData or similar) for v1.
- Local notifications for pacing reminders.
- Ride and emergency buttons can open the phone dialer / maps / a taxi app link.

## 5. Design system

**Look:** simple and neat. Dark charcoal background, grey rounded cards, **mint is the only accent colour**. Rounded friendly font. No emoji.

| Role | Colour | Hex |
|---|---|---|
| Background | Charcoal | `#1A1A1C` |
| Cards | Dark grey | `#262628` |
| Buttons on cards / icon tiles | Mid grey | `#353538` |
| Main accent (primary buttons, glass fill, logo, highlighted word) | Mint | `#6EE7C1` |
| Text on mint | Charcoal | `#1A1A1C` |
| Secondary accent (water, progress gradient end) | Sky blue | `#5CC8F5` |
| "Plan reached" / slow down | Orange | `#FF8A3D` |
| Emergency only | Red | `#E5484D` (soft red text `#FF9B8F`) |
| Text | White | `#FFFFFF` |
| Secondary text | Grey | `#9A9AA0` |

- Progress bar: gradient mint `#6EE7C1` → sky blue `#5CC8F5`.
- Red appears **only** for emergency/help.
- **Font:** Outfit (Google Fonts) — weights 400–800. Headings 800, buttons 700. One word in each main heading is mint, e.g. "Going out **tonight?**", "Nice and **steady**", "You stuck to your **plan**".
- Corners: cards 22–28 px, primary buttons fully rounded (pill), 62 px tall.
- Touch targets at least 44 px.
- Icons: simple line icons (SF Symbols in SwiftUI are fine).

## 6. Logo

Options are in `design/` (LogoTilt, LogoHalf, LogoRing, LogoApp, LogoLockup, LogoTipped, LogoTippedApp).
- Chosen logo: **Logo A — tilted glass** (`LogoTilt.dc.html`): white tilted cocktail glass, mint drink, two mint bubbles on charcoal. Used for the app icon and in-app logo.
- Note: it was based on a reference image — check that image's licence or change the design enough before using it officially.

## 7. Design files

`design/` contains HTML mockups (390 × 844 phone screens) you can open in a browser as an exact visual reference:
- `Main.dc.html` — Home
- `Drink.dc.html` — Drink mode
- `Summary.dc.html` — Night summary
- `Help.dc.html` — Need help
- `Logo*.dc.html` — logo options
- `canvas.json` — layout of the design canvas

They are written in a canvas mockup format (inline styles, a small script block at the bottom with sample data). Use them for layout, spacing, colours and copy — rebuild them natively in SwiftUI rather than embedding the HTML.

## 8. First steps for Claude Code

1. Set up a new SwiftUI Xcode project called Pacey (iOS 17+).
2. Add the colour palette and Outfit font as a small design system.
3. Build the four screens and the flow: Home → Drink mode → Summary, with Need help reachable from Home and Drink mode.
4. Add the age gate, local storage and pacing notifications.
5. Test on a real iPhone.
