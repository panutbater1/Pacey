// Builds the phone web version of Pacey into web-dist/ (a static folder for GitHub Pages).
//   npm run web          build it
//   npm run web:serve    build it and open it at http://localhost:8080
// Same prototype and runtime as the laptop app, with the web switch on:
// no sign-up, no Electron, real clock, data saved on the phone.
const fs = require('fs');
const path = require('path');
const { readPrototype, generatedJs } = require('../desktop/build-lib');

const root = path.join(__dirname, '..');
const desktopApp = path.join(root, 'desktop', 'app');
const out = path.join(root, 'web-dist');

function findReact(file) {
  const p = path.join(root, 'desktop', 'node_modules', file);
  if (!fs.existsSync(p)) {
    throw new Error('Missing ' + file + '. Run `npm install` in the desktop folder (or `npm start` once), then try again.');
  }
  return p;
}

function copy(from, to) {
  fs.mkdirSync(path.dirname(to), { recursive: true });
  fs.copyFileSync(from, to);
}

fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });

// The app: sign-in settings stay empty on purpose (sign-up is off in the web version).
const build = Object.assign(readPrototype(), { web: true, config: {} });
fs.writeFileSync(path.join(out, 'generated.js'), generatedJs(build));

copy(path.join(desktopApp, 'runtime.js'), path.join(out, 'runtime.js'));
copy(findReact('react/umd/react.production.min.js'), path.join(out, 'vendor', 'react.production.min.js'));
copy(findReact('react-dom/umd/react-dom.production.min.js'), path.join(out, 'vendor', 'react-dom.production.min.js'));
for (const f of fs.readdirSync(path.join(desktopApp, 'fonts'))) {
  copy(path.join(desktopApp, 'fonts', f), path.join(out, 'fonts', f));
}
for (const f of fs.readdirSync(path.join(__dirname, 'icons'))) {
  copy(path.join(__dirname, 'icons', f), path.join(out, 'icons', f));
}
copy(path.join(__dirname, 'index.html'), path.join(out, 'index.html'));
copy(path.join(__dirname, 'manifest.webmanifest'), path.join(out, 'manifest.webmanifest'));
// GitHub Pages: serve the files as they are.
fs.writeFileSync(path.join(out, '.nojekyll'), '');

console.log('Built web-dist/ from prototype/Main.dc.html (phone web version)');
