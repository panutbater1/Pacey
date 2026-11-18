# Pacey on your laptop

Runs Pacey as a real app in a phone-shaped window: real time, your nights saved between launches, and notifications from your computer.

## First time

1. Install **Node.js** (the LTS version) from https://nodejs.org if you don't have it.
2. In a terminal, go into this folder and install:

```bash
cd desktop
```

```bash
npm install
```

## Open the app

```bash
npm start
```

A phone-sized Pacey window opens. Close the window to quit.

## Testing mode

```bash
npm run dev
```

The same app, plus the testing buttons: **Skip setup** during first launch and **Lock** (top left during a night) to preview the lock screen widgets and Live Activity.

## How it works

- The app is built from `../prototype/Main.dc.html` every time you start it, so it always matches the prototype.
- Unlike the prototype, it uses the real clock (no sped-up time) and starts with no sample nights.
- Everything you enter is saved on this computer. To start again from the welcome screen, open the developer tools (View › Toggle Developer Tools) and run `paceyReset()` in the console.
- The phone shrinks to fit if your screen is small.
