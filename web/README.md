# Pacey on the phone (web test version)

- `npm run web` builds `web-dist/` from `prototype/Main.dc.html` with the shared runtime (`desktop/app/runtime.js`) and the web switch on: no sign-up, no Electron, real clock, reminders as in-app banners, data saved on the phone (`localStorage`).
- `npm run web:serve` builds it and serves it at http://localhost:8080 (open that on a phone on the same Wi-Fi with this computer's address to test).
- `npm run web:publish` builds it again, copies `web-dist/` into the `gh-pages` branch (through a temporary git worktree, with an empty `.nojekyll`), commits and pushes that branch. **Only run it after Arthur says "push".**
- First time only: on GitHub, Settings › Pages › Source "Deploy from a branch", branch `gh-pages`, folder `/ (root)`. The site is https://panutbater1.github.io/Pacey/ (all paths are relative, so it works there).
- `web-dist/` is never committed to `main` (it's in `.gitignore`); the icons in `web/icons/` come from `desktop/app/icon.png` (LogoTilt).
