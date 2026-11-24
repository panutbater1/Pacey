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
    return { path: require(path.join(desktop, 'node_modules', 'electron')) };
  } catch (e) {
    return { error: e.message };
  }
}

// Newer npm versions block package setup scripts unless they are approved, which stops Electron
// downloading itself. So Pacey runs Electron's download step itself when it is missing.
function downloadElectron() {
  console.log('Pacey: downloading Electron (about 100 MB, only the first time)...');
  const env = Object.assign({}, process.env);
  delete env.ELECTRON_SKIP_BINARY_DOWNLOAD;
  const result = spawnSync(process.execPath, [path.join(desktop, 'node_modules', 'electron', 'install.js')], { cwd: desktop, stdio: 'inherit', env: env });
  delete require.cache[require.resolve(path.join(desktop, 'node_modules', 'electron'))];
  return result.status;
}

// On some Node versions Electron's own unzip step stops halfway without an error, leaving a
// half-unpacked app. On a Mac, unzip the downloaded file with the built-in ditto tool instead.
function unzipElectronOnMac() {
  if (process.platform !== 'darwin') return false;
  const os = require('os');
  const version = require(path.join(desktop, 'node_modules', 'electron', 'package.json')).version;
  const cache = path.join(os.homedir(), 'Library', 'Caches', 'electron');
  const want = 'electron-v' + version + '-darwin-' + process.arch + '.zip';
  let zip = null;
  const walk = (dir, depth) => {
    if (zip || depth > 3 || !fs.existsSync(dir)) return;
    for (const name of fs.readdirSync(dir)) {
      const full = path.join(dir, name);
      if (name === want) { zip = full; return; }
      try { if (fs.statSync(full).isDirectory()) walk(full, depth + 1); } catch (e) { /* skip */ }
    }
  };
  walk(cache, 0);
  if (!zip) return false;
  console.log('Pacey: unpacking Electron with the Mac\'s own unzip tool...');
  const electronDir = path.join(desktop, 'node_modules', 'electron');
  const dist = path.join(electronDir, 'dist');
  fs.rmSync(dist, { recursive: true, force: true });
  const r = spawnSync('ditto', ['-x', '-k', zip, dist], { stdio: 'inherit' });
  if (r.status !== 0) return false;
  fs.writeFileSync(path.join(electronDir, 'path.txt'), 'Electron.app/Contents/MacOS/Electron');
  delete require.cache[require.resolve(path.join(desktop, 'node_modules', 'electron'))];
  return true;
}

let electron = findElectron();
if (!electron.path) {
  const status = downloadElectron();
  electron = findElectron();
  if (!electron.path && unzipElectronOnMac()) electron = findElectron();
  if (!electron.path) {
    console.error('');
    console.error('Pacey: Electron did not download (exit code ' + status + ').');
    console.error('Reason: ' + electron.error);
    console.error('Check your internet connection, then run this again. If it keeps happening, run:');
    console.error('  cd "' + desktop + '" && npm install-scripts approve electron && npm rebuild electron');
    process.exit(1);
  }
}
electron = electron.path;

console.log('Pacey: opening...');
const child = spawn(electron, [desktop].concat(args), { stdio: 'ignore', detached: true });
child.on('error', (err) => {
  console.error('Pacey: could not open the app: ' + err.message);
  process.exit(1);
});
// Give the terminal back straight away; the window keeps running on its own.
child.unref();
