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
for (const f of ['generated.js', 'runtime.js', 'index.html']) {
  if (/service_role|eyJhbGci/.test(fs.readFileSync(path.join(dist, f), 'utf8'))) {
    throw new Error('Stopped: ' + f + ' looks like it contains a key. Nothing was published.');
  }
}

// 3. Check out gh-pages in a temporary folder (start the branch if it doesn't exist yet).
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'pacey-gh-pages-'));
let hasRemote = false;
try { git(['fetch', 'origin', 'gh-pages']); hasRemote = true; } catch (e) { hasRemote = false; }
try {
  if (hasRemote) git(['worktree', 'add', '-B', 'gh-pages', tmp, 'origin/gh-pages']);
  else {
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
