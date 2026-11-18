#!/usr/bin/env node
// Opens Pacey in its phone-sized window. Installs what it needs the first time.
//   npm start            (from the Pacey folder)
//   pacey                (anywhere, after a one-time `npm install -g .` in the Pacey folder)
//   pacey --dev          (with the testing buttons)
//   pacey --demo         (sample nights and sped-up time, nothing saved)
const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const desktop = path.join(__dirname, '..', 'desktop');
const isWindows = process.platform === 'win32';
const args = process.argv.slice(2);

if (!fs.existsSync(path.join(desktop, 'package.json'))) {
  console.error('Pacey: could not find the desktop app at ' + desktop);
  console.error('Download the latest Pacey from GitHub and try again.');
  process.exit(1);
}

// First run: install the app's packages (this downloads Electron, so it takes a minute).
if (!fs.existsSync(path.join(desktop, 'node_modules', 'electron'))) {
  console.log('Pacey: setting up for the first time. This takes a minute...');
  const npm = isWindows ? 'npm.cmd' : 'npm';
  const result = spawnSync(npm, ['install', '--no-audit', '--no-fund'], { cwd: desktop, stdio: 'inherit', shell: isWindows });
  if (result.status !== 0) {
    console.error('Pacey: setup failed. Check your internet connection and run this again.');
    process.exit(result.status || 1);
  }
}

// Build the app from the prototype, then open it.
require(path.join(desktop, 'build.js'));

function findElectron() {
  try {
    return require(path.join(desktop, 'node_modules', 'electron'));
  } catch (e) {
    return null;
  }
}

let electron = findElectron();
if (!electron) {
  // The Electron download can fail on a flaky connection: try it once more.
  console.log('Pacey: finishing setup...');
  spawnSync(process.execPath, [path.join(desktop, 'node_modules', 'electron', 'install.js')], { cwd: desktop, stdio: 'inherit' });
  delete require.cache[require.resolve(path.join(desktop, 'node_modules', 'electron'))];
  electron = findElectron();
}
if (!electron) {
  console.error('Pacey: Electron is not installed correctly. Delete the desktop/node_modules folder and run this again.');
  process.exit(1);
}

console.log('Pacey: opening...');
const child = spawn(electron, [desktop].concat(args), { stdio: 'ignore', detached: true });
child.on('error', (err) => {
  console.error('Pacey: could not open the app: ' + err.message);
  process.exit(1);
});
// Give the terminal back straight away; the window keeps running on its own.
child.unref();
