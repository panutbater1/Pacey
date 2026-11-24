// Pacey desktop: opens the app in a phone-sized window.
const { app, BrowserWindow, screen, shell, ipcMain } = require('electron');
const path = require('path');
const { googleSignIn } = require('./google-sign-in');

const DEV = process.argv.includes('--dev');
const DEMO = process.argv.includes('--demo');
// Window size that fits the phone (390 x 844 screen + body) with a small margin.
const BASE_WIDTH = 462;
const BASE_HEIGHT = 916;

app.setName('Pacey');
if (process.platform === 'win32') app.setAppUserModelId('com.pacey.desktop');

function createWindow() {
  // Shrink the whole phone on smaller laptop screens so it always fits.
  const { height } = screen.getPrimaryDisplay().workAreaSize;
  const zoom = Math.min(1, (height - 16) / BASE_HEIGHT);

  const win = new BrowserWindow({
    width: Math.round(BASE_WIDTH * zoom),
    height: Math.round(BASE_HEIGHT * zoom),
    useContentSize: true,
    resizable: false,
    maximizable: false,
    fullscreenable: false,
    title: 'Pacey',
    backgroundColor: '#0E0E10',
    autoHideMenuBar: true,
    icon: path.join(__dirname, 'app', 'icon.png'),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  win.loadFile(path.join(__dirname, 'app', 'index.html'), { query: { dev: DEV ? '1' : '0', demo: DEMO ? '1' : '0' } });
  win.webContents.on('did-finish-load', () => win.webContents.setZoomFactor(zoom));

  // Links such as tel:, sms: and https: open in the operating system, never inside the app.
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (event, url) => {
    if (!url.startsWith('file://')) {
      event.preventDefault();
      shell.openExternal(url);
    }
  });
}

// Google sign-in runs here, in the main process, because it opens the person's browser.
ipcMain.handle('pacey:google-sign-in', (event, settings) => googleSignIn(settings));

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
