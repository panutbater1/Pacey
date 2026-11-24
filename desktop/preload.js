// Gives the app window one safe door to the main process: Google sign-in, which has to open
// the person's own browser and catch the reply on this computer.
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('paceyNative', {
  googleSignIn: (settings) => ipcRenderer.invoke('pacey:google-sign-in', settings)
});
