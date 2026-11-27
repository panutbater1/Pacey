// Publishes the phone web version to GitHub Pages: builds web-dist/, then commits it to the
// gh-pages branch (through a temporary git worktree) and pushes that branch.
//   npm run web:publish     Only run this when Arthur says "push".
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const root = path.join(__dirname, '..');
const dist = path.join(root, 'web-dist');
const git = (args, cwd = root) => execFileSync('git', args, { cwd, stdio: 'pipe' }).toString().trim();

// 1. Fresh build.
require('./build');

// 2. Never publish keys: the web version has sign-up off, so no Supabase settings belong here.
//    Checks every file in web-dist for secret keys, JWTs (service_role keys start eyJhbGci) and bot tokens.
const KEY_PATTERNS = [/sb_secret_/, /service_role/, /eyJhbGci/, /\d{8,10}:[A-Za-z0-9_-]{35}/];
const allFiles = (dir) => fs.readdirSync(dir, { withFileTypes: true })
  .flatMap((e) => e.isDirectory() ? allFiles(path.join(dir, e.name)) : [path.join(dir, e.name)]);
for (const f of allFiles(dist)) {
  const text = fs.readFileSync(f, 'latin1');
  if (KEY_PATTERNS.some((re) => re.test(text))) {
    throw new Error('Stopped: ' + path.relative(dist, f) + ' looks like it contains a key. Nothing was published.');
  }
}

// 3. Check out gh-pages in a temporary folder (start the branch if it doesn't exist yet).
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'pacey-gh-pages-'));
let hasRemote = false;
try { git(['fetch', 'origin', 'gh-pages']); hasRemote = true; } catch (e) { hasRemote = false; }
try {
  let hasLocal = true;
  try { git(['rev-parse', '--verify', '--quiet', 'refs/heads/gh-pages']); } catch (e) { hasLocal = false; }
  if (hasRemote) git(['worktree', 'add', '-B', 'gh-pages', tmp, 'origin/gh-pages']);
  else if (hasLocal) {
    // First publish after a run that made the branch here but never pushed it: reuse it.
    console.log('No gh-pages on GitHub yet; using the local gh-pages branch.');
    try { git(['worktree', 'add', tmp, 'gh-pages']); }
    catch (e) { throw new Error('Could not use the local gh-pages branch (is it open in another folder? try "git worktree prune"). Nothing was published.'); }
  } else {
    git(['worktree', 'add', '--detach', tmp]);
    git(['checkout', '--orphan', 'gh-pages'], tmp);
  }

  // 4. Replace everything with the new build (keep .git), then commit and push.
  for (const f of fs.readdirSync(tmp)) if (f !== '.git') fs.rmSync(path.join(tmp, f), { recursive: true, force: true });
  fs.cpSync(dist, tmp, { recursive: true });
  git(['add', '-A'], tmp);
  if (!git(['status', '--porcelain'], tmp)) { console.log('Nothing changed since the last publish.'); }
  else {
    const from = git(['rev-parse', '--short', 'HEAD']);
    git(['commit', '-m', 'Publish Pacey web version (from ' + from + ')'], tmp);
    git(['push', 'origin', 'gh-pages'], tmp);
    console.log('Published. In a minute or two it is live at https://panutbater1.github.io/Pacey/');
  }
} finally {
  try { git(['worktree', 'remove', '--force', tmp]); } catch (e) { fs.rmSync(tmp, { recursive: true, force: true }); }
}
