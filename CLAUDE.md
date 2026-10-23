# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

Only the `index.html` shell exists so far. `sales.html`, `menu.html`, `reviews.html` and `promo.html` are not written yet, and nothing is wired to Supabase or the `cafe-ai` Edge Function. The product spec is in `PRD.md`, including its open questions (login, shared CSS, and others). `origin` is `https://github.com/pinggu092414/day4-cafe.git`.

## Running

There is no npm, build step, test suite, or linter by design (see `PRD.md`). Serve the folder with the PowerShell static server, which needs no install. Real Python and Node are not installed here; `python` on PATH is only the Microsoft Store stub.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1 -Port 8000
```

`.claude/launch.json` defines the same command as the `cafe` preview server. `serve.ps1` binds to `localhost` only, sends `Cache-Control: no-store`, and returns 404 for `.git`.

## Architecture

- `index.html` is the shell: a left menu plus a center area. The menu is built from the `pages` array in its script, and the selected page is kept in the URL hash (`#home`, `#sales`, `#menu`, `#reviews`, `#promo`), so refresh and the back button work.
- Each page except home is a separate HTML file loaded into one `<iframe>`.
- Before loading a page the shell sends `HEAD <file>`. If the file is missing it shows the "준비중" panel instead of the iframe. A new page therefore appears as soon as its file exists; only the `pages` array in `index.html` needs a new entry if a menu item is added. Over `file://` the check is skipped and the iframe is always used.
- Home has no content yet and shows "준비중". Per `PRD.md`, its cards, 7-day sales chart and AI briefing are meant to live inside `index.html` itself.
- The shared colors and font are CSS variables in `index.html`'s `:root`. The other pages will be separate documents inside iframes, so they must copy those values (or share a CSS file; that decision is still open in `PRD.md`).

## Environment

- Windows 10 with PowerShell 5.1, so `&&` and `||` are not available; chain with `;` or `if ($?) { ... }`.
- Git was installed via winget after this folder was created. A terminal opened before that may not have `git` on its PATH; open a new terminal or refresh `$env:Path`.
- The branch is `main`, pushed to `origin`. Commits in this repo use the repo-local identity `pinggu092414 <pinggu092414@users.noreply.github.com>` so the personal email is not published.
