// A small runtime that renders the prototype's template with React.
// Supports what the prototype uses: {{holes}}, <sc-if>, <sc-for>, events, refs and inline styles.
(function () {
  'use strict';

  const h = React.createElement;
  const Fragment = React.Fragment;
  const build = window.PACEY_BUILD;
  const params = new URLSearchParams(window.location.search);
  const DEV = params.get('dev') === '1';
  // Demo mode: the prototype's sample nights and sped-up clock, nothing saved.
  const DEMO = params.get('demo') === '1';
  const STORAGE_KEY = 'pacey.state.v1';

  // Screens and keys that shouldn't come back after a restart.
  const TRANSIENT = ['banner', 'anim', 'picker', 'pickerTarget', 'typeMenu', 'legalSheet', 'islandOpen',
    'waterFirst', 'tickHint', 'emailErr', 'passwordDraft', 'confirmDelAcct', 'planDrinkOpen', 'bigPlanAsk', 'quickOpen', 'timeAsk', 'earlyAsk', 'endAsk', 'hourSel', 'quickAt', 'deleteNightAsk', 'raiseLimitAsk', 'iconPickFor', 'accountBusy', 'accountNote', 'accountErr', 'taxiSheet'];

  // ---------- styles from the prototype
  const style = document.createElement('style');
  style.textContent = build.css;
  document.head.appendChild(style);

  // ---------- compile the template once
  const HOLE = /\{\{\s*([^}]+?)\s*\}\}/g;
  let nextId = 0;

  function parseParts(str) {
    const parts = [];
    let last = 0;
    str.replace(HOLE, (match, path, offset) => {
      if (offset > last) parts.push(str.slice(last, offset));
      parts.push({ hole: path });
      last = offset + match.length;
      return match;
    });
    if (last < str.length) parts.push(str.slice(last));
    return parts;
  }

  function holePath(value) {
    const m = (value || '').match(/^\s*\{\{\s*([^}]+?)\s*\}\}\s*$/);
    return m ? m[1] : value;
  }

  function compile(node) {
    if (node.nodeType === 3) return { t: 'text', parts: parseParts(node.nodeValue) };
    if (node.nodeType !== 1) return null;
    const tag = node.localName; // keeps SVG casing, e.g. clipPath
    const children = Array.from(node.childNodes).map(compile).filter(Boolean);
    if (tag === 'sc-if') return { t: 'if', value: holePath(node.getAttribute('value')), children, id: nextId++ };
    if (tag === 'sc-for') {
      return { t: 'for', list: holePath(node.getAttribute('list')), as: node.getAttribute('as'), children, id: nextId++ };
    }
    const attrs = [];
    for (const a of Array.from(node.attributes)) {
      if (a.name.startsWith('hint-') || a.name === 'xmlns') continue;
      attrs.push({ name: a.name, parts: parseParts(a.value) });
    }
    return { t: 'el', tag, attrs, children };
  }

  const doc = new DOMParser().parseFromString('<!doctype html><body>' + build.template + '</body>', 'text/html');
  const TREE = Array.from(doc.body.childNodes).filter((n) => n.nodeType === 1).map(compile);

  // ---------- rendering
  function lookup(path, scope) {
    if (path === 'true') return true;
    if (path === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(path)) return Number(path);
    const keys = path.split('.');
    let value = scope[keys[0]];
    for (let i = 1; i < keys.length; i += 1) {
      if (value == null) return undefined;
      value = value[keys[i]];
    }
    return value;
  }

  function evalParts(parts, scope) {
    if (parts.length === 1 && typeof parts[0] === 'object') return lookup(parts[0].hole, scope);
    return parts.map((p) => {
      if (typeof p === 'string') return p;
      const v = lookup(p.hole, scope);
      return v == null ? '' : String(v);
    }).join('');
  }

  function parseStyle(text) {
    const out = {};
    for (const decl of text.split(';')) {
      const i = decl.indexOf(':');
      if (i < 0) continue;
      let key = decl.slice(0, i).trim();
      const value = decl.slice(i + 1).trim();
      if (!key) continue;
      if (!key.startsWith('--')) {
        key = key.replace(/^-webkit-/, 'Webkit-').replace(/-([a-z])/g, (m, c) => c.toUpperCase());
      }
      out[key] = value;
    }
    return out;
  }

  const ATTR = {
    class: 'className', for: 'htmlFor', onclick: 'onClick', onchange: 'onChange', onscroll: 'onScroll',
    oninput: 'onInput', onpointerdown: 'onPointerDown', onpointerup: 'onPointerUp',
    onpointerleave: 'onPointerLeave', onpointercancel: 'onPointerCancel', oncontextmenu: 'onContextMenu', autocomplete: 'autoComplete', tabindex: 'tabIndex', readonly: 'readOnly', maxlength: 'maxLength'
  };

  function renderNodes(list, scope) {
    return list.map((node) => renderNode(node, scope));
  }

  function renderNode(node, scope) {
    if (node.t === 'text') {
      const v = evalParts(node.parts, scope);
      return v == null ? '' : String(v);
    }
    if (node.t === 'if') {
      return lookup(node.value, scope) ? h(Fragment, { key: 'i' + node.id }, ...renderNodes(node.children, scope)) : null;
    }
    if (node.t === 'for') {
      const items = lookup(node.list, scope) || [];
      return h(Fragment, { key: 'f' + node.id }, items.map((item, index) => {
        const inner = Object.create(scope);
        inner[node.as] = item;
        inner.$index = index;
        return h(Fragment, { key: index }, ...renderNodes(node.children, inner));
      }));
    }
    const props = {};
    for (const a of node.attrs) {
      const value = evalParts(a.parts, scope);
      if (a.name === 'style') { props.style = parseStyle(value == null ? '' : String(value)); continue; }
      const name = ATTR[a.name] || a.name;
      if (/^on[A-Z]/.test(name) && typeof value !== 'function') continue;
      props[name] = value;
    }
    if (node.tag === 'input' && 'value' in props && !props.onChange) props.readOnly = true;
    return h(node.tag, props, ...renderNodes(node.children, scope));
  }

  // ---------- saving between launches
  let saveTimer = null;
  function save(state) {
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => {
      try {
        const copy = Object.assign({}, state);
        TRANSIENT.forEach((k) => { delete copy[k]; });
        if (copy.screen === 'lock' || copy.screen === 'help') copy.screen = copy.lockReturn || copy.helpFrom || 'home';
        localStorage.setItem(STORAGE_KEY, JSON.stringify(copy));
      } catch (e) { /* storage full or blocked: keep running */ }
    }, 250);
  }

  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      return null;
    }
  }

  class DCLogic extends React.Component {
    componentDidUpdate() { if (!DEMO) save(this.state); }
    render() {
      const vals = this.renderVals();
      return h(Fragment, null, ...renderNodes(TREE, vals));
    }
  }

  // ---------- notifications from the operating system
  window.paceyNotify = function (title, body) {
    if (!('Notification' in window)) return;
    const show = () => { try { new Notification(title, { body: body }); } catch (e) { /* ignore */ } };
    if (Notification.permission === 'granted') show();
    else if (Notification.permission !== 'denied') Notification.requestPermission().then((p) => { if (p === 'granted') show(); });
  };

  window.paceyRequestNotify = function () {
    if ('Notification' in window && Notification.permission === 'default') Notification.requestPermission();
  };

  // ---------- real sign-in (Supabase), when pacey.config.json has a project URL and key
  const AUTH_KEY = 'pacey.auth.v1';
  const cfg = build.config || {};
  const authOn = !!(cfg.supabaseUrl && cfg.supabaseAnonKey) && !DEMO;

  function readSession() {
    try { return JSON.parse(localStorage.getItem(AUTH_KEY) || 'null'); } catch (e) { return null; }
  }
  function writeSession(sess) {
    try { if (sess) localStorage.setItem(AUTH_KEY, JSON.stringify(sess)); else localStorage.removeItem(AUTH_KEY); } catch (e) { /* ignore */ }
  }
  function keep(json) {
    const sess = { access: json.access_token, refresh: json.refresh_token, expiresAt: Date.now() + (json.expires_in || 3600) * 1000, user: json.user };
    writeSession(sess);
    return sess;
  }
  function friendly(json, status) {
    const msg = String((json && (json.msg || json.error_description || json.message || json.error)) || '');
    if (/invalid login credentials/i.test(msg)) return 'That email and password don\'t match.';
    if (/already registered|already exists/i.test(msg)) return 'There\'s already an account with that email. Sign in instead.';
    if (/email not confirmed/i.test(msg)) return 'Confirm your email first: open the link we sent you, then sign in.';
    if (/password/i.test(msg) && /(short|weak|at least)/i.test(msg)) return 'Choose a longer or stronger password.';
    if (/rate limit|too many/i.test(msg) || status === 429) return 'Too many tries. Wait a minute and try again.';
    return msg ? 'Sign-in problem: ' + msg : 'Something went wrong. Try again.';
  }
  async function call(pathPart, body, token, method) {
    let res;
    try {
      res = await fetch(cfg.supabaseUrl + pathPart, {
        method: method || 'POST',
        headers: Object.assign({ apikey: cfg.supabaseAnonKey, 'Content-Type': 'application/json' }, token ? { Authorization: 'Bearer ' + token } : {}),
        body: body === undefined ? undefined : JSON.stringify(body)
      });
    } catch (e) {
      return { ok: false, error: 'Couldn\'t reach the sign-in service. Check your internet connection.' };
    }
    let json = null;
    try { json = await res.json(); } catch (e) { json = null; }
    return res.ok ? { ok: true, json: json } : { ok: false, error: friendly(json, res.status), status: res.status };
  }
  async function freshToken() {
    const sess = readSession();
    if (!sess) return null;
    if (sess.expiresAt - Date.now() > 60000) return sess.access;
    const r = await call('/auth/v1/token?grant_type=refresh_token', { refresh_token: sess.refresh });
    return r.ok ? keep(r.json).access : null;
  }
  const userOut = (u) => ({ id: u.id, email: u.email, plan: u.user_metadata && u.user_metadata.plan, avg: u.user_metadata && u.user_metadata.avg });

  window.paceyAuth = {
    enabled: authOn,
    async signUp(email, password, data) {
      const r = await call('/auth/v1/signup', { email: email, password: password, data: data || {} });
      if (!r.ok) return { error: r.error };
      if (r.json && r.json.access_token) return { user: userOut(keep(r.json).user) };
      // Email confirmation is switched on in Supabase: the account exists, but needs the link first.
      return { needsConfirm: true };
    },
    async signIn(email, password) {
      const r = await call('/auth/v1/token?grant_type=password', { email: email, password: password });
      if (!r.ok) return { error: r.error };
      return { user: userOut(keep(r.json).user) };
    },
    async savePlan(data) {
      const token = await freshToken();
      if (!token) return { error: 'Signed out' };
      const r = await call('/auth/v1/user', { data: data }, token, 'PUT');
      return r.ok ? { ok: true } : { error: r.error };
    },
    async signOut() {
      const sess = readSession();
      writeSession(null);
      if (sess) await call('/auth/v1/logout', {}, sess.access);
      return { ok: true };
    },
    async deleteAccount() {
      const token = await freshToken();
      if (!token) return { error: 'Sign in again, then delete your account.' };
      // Needs the delete_user function from desktop/README.md in the Supabase project.
      const r = await call('/rest/v1/rpc/delete_user', {}, token);
      if (!r.ok) return { error: r.status === 404 ? 'Account deletion isn\'t set up yet (see the Supabase steps in desktop/README.md).' : r.error };
      writeSession(null);
      return { ok: true };
    }
  };

  // ---------- start
  const Component = new Function('DCLogic', 'React', build.code + '\nreturn Component;')(DCLogic, React);
  const props = Object.assign({}, build.defaults, { devSkip: DEV || DEMO, realtime: !DEMO, savedState: DEMO ? null : load() });
  ReactDOM.createRoot(document.getElementById('screen')).render(h(Component, props));

  window.paceyReset = function () {
    localStorage.removeItem(STORAGE_KEY);
    window.location.reload();
  };
})();
