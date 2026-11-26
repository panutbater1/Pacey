// Google sign-in for the laptop app, through Supabase.
// Opens Google in the person's own browser, catches the reply on this computer
// (http://127.0.0.1:53682/auth/callback) and swaps it for a Supabase session (PKCE flow).
const http = require('http');
const crypto = require('crypto');
const { shell } = require('electron');

const PORT = 53682;
const REDIRECT = 'http://127.0.0.1:' + PORT + '/auth/callback';
const TIMEOUT_MS = 5 * 60 * 1000;

const b64url = (buf) => buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

function page(title, text) {
  return '<!doctype html><meta charset="utf-8"><title>Pacey</title>' +
    '<body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:#1A1A1C;color:#fff;font-family:system-ui,sans-serif;text-align:center">' +
    '<div><h1 style="font-size:28px;margin:0 0 8px">' + title + '</h1><p style="color:#9A9AA0;font-size:17px;margin:0">' + text + '</p></div></body>';
}

let running = null;
let cancelRunning = null;

async function googleSignIn(settings) {
  const url = String((settings && settings.supabaseUrl) || '').replace(/\/+$/, '');
  const key = String((settings && settings.anonKey) || '');
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.co$/.test(url) || !key) return { error: 'Google sign-in isn\'t set up.' };
  // A new try replaces one that never finished (for example, the browser was closed while offline).
  if (running) { cancelGoogleSignIn(); await running.catch(() => {}); }

  const verifier = b64url(crypto.randomBytes(32));
  const challenge = b64url(crypto.createHash('sha256').update(verifier).digest());

  running = new Promise((resolve) => {
    let done = false;
    const finish = (result) => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      cancelRunning = null;
      server.close();
      if (server.closeAllConnections) server.closeAllConnections();
      resolve(result);
    };
    cancelRunning = () => finish({ cancelled: true, error: 'Google sign-in was cancelled.' });
    const server = http.createServer(async (req, res) => {
      const u = new URL(req.url, REDIRECT);
      if (u.pathname !== '/auth/callback') { res.writeHead(404); res.end(); return; }
      const code = u.searchParams.get('code');
      const err = u.searchParams.get('error_description') || u.searchParams.get('error');
      if (!code) {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(page('Sign-in cancelled', 'You can close this tab and go back to Pacey.'));
        finish({ error: err ? 'Google sign-in didn\'t finish: ' + err : 'Google sign-in was cancelled.' });
        return;
      }
      try {
        const r = await fetch(url + '/auth/v1/token?grant_type=pkce', {
          method: 'POST',
          headers: { apikey: key, 'Content-Type': 'application/json' },
          body: JSON.stringify({ auth_code: code, code_verifier: verifier })
        });
        const json = await r.json().catch(() => null);
        if (!r.ok || !json || !json.access_token) throw new Error((json && (json.msg || json.error_description || json.error)) || 'no session');
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(page('You\'re signed in', 'You can close this tab and go back to Pacey.'));
        finish({ session: json });
      } catch (e) {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(page('Something went wrong', 'Go back to Pacey and try again.'));
        finish({ error: 'Google sign-in didn\'t finish. Try again.' });
      }
    });
    const timer = setTimeout(() => finish({ error: 'Google sign-in timed out. Try again.' }), TIMEOUT_MS);
    server.on('error', () => finish({ error: 'Couldn\'t start Google sign-in on this computer. Close other copies of Pacey and try again.' }));
    server.listen(PORT, '127.0.0.1', () => {
      const auth = url + '/auth/v1/authorize?provider=google' +
        '&redirect_to=' + encodeURIComponent(REDIRECT) +
        '&code_challenge=' + challenge + '&code_challenge_method=s256';
      shell.openExternal(auth);
    });
  });

  try {
    return await running;
  } finally {
    running = null;
  }
}

// Cancel from the app: stops waiting for the browser and frees the port so a retry works.
function cancelGoogleSignIn() {
  if (cancelRunning) cancelRunning();
  return { ok: true };
}

module.exports = { googleSignIn, cancelGoogleSignIn };
