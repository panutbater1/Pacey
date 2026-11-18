# Pacey on your laptop

Runs Pacey as a real app in a phone-shaped window: real time, your nights saved between launches, and notifications from your computer.

## Open the app

From the main Pacey folder (one level up from here):

```bash
npm start
```

Or type `pacey` in any terminal after a one-time `npm install -g .` in the main Pacey folder. The first launch sets itself up, which takes about a minute.

You can also run it from this folder with `npm install` once, then `npm start`.

## Testing mode

```bash
pacey --dev
```

Shows the testing buttons: **Skip setup** during first launch and **Lock** (top left during a night) to preview the lock screen widgets and Live Activity.

## Demo mode

```bash
pacey --demo
```

Opens with the prototype's sample nights and sped-up time (one second is one minute), so you can see the charts, Weeks, Months, All time and Calories filled in. Nothing you do in demo mode is saved.

## How it works

- The app is built from `../prototype/Main.dc.html` every time you start it, so it always matches the prototype.
- Unlike the prototype, it uses the real clock (no sped-up time) and starts with no sample nights.
- Everything you enter is saved on this computer. To start again from the welcome screen, open the developer tools (View › Toggle Developer Tools) and run `paceyReset()` in the console.
- The phone shrinks to fit if your screen is small.
