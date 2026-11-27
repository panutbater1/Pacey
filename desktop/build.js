// Turns the prototype (prototype/Main.dc.html) into app/generated.js for the desktop app.
// Runs automatically before `npm start`, so the desktop app always matches the prototype.
const fs = require('fs');
const path = require('path');
const { readPrototype, generatedJs } = require('./build-lib');

const out = path.join(__dirname, 'app', 'generated.js');

// Sign-in settings (pacey.config.json, or the PACEY_SUPABASE_URL / PACEY_SUPABASE_ANON_KEY environment variables).
let config = {};
try { config = JSON.parse(fs.readFileSync(path.join(__dirname, 'pacey.config.json'), 'utf8')); } catch (e) { config = {}; }
const supabaseUrl = (process.env.PACEY_SUPABASE_URL || config.supabaseUrl || '').trim().replace(/\/+$/, '');
const supabaseAnonKey = (process.env.PACEY_SUPABASE_ANON_KEY || config.supabaseAnonKey || '').trim();

// Google sign-in: turn on with "googleSignIn": true once the Google provider is set up in Supabase.
const googleSignIn = config.googleSignIn === true;

const build = Object.assign(readPrototype(), { config: { supabaseUrl, supabaseAnonKey, googleSignIn } });
fs.writeFileSync(out, generatedJs(build));
console.log('Built app/generated.js from prototype/Main.dc.html' + (supabaseUrl && supabaseAnonKey ? ' (real sign-in on)' : ''));
