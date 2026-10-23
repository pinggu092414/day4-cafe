# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current state

`index.html` (the shell), `menu.html` and `sales.html` exist. `reviews.html` and `promo.html` are not written yet, and the `cafe-ai` Edge Function is not wired in. The Supabase project is `day4-cafe` (`gdtwycpjbnxhqrkbwkmn`), with tables `menus`, `sales` and `reviews`. The product spec is in `PRD.md`, including its open questions (login, shared CSS, and others). `origin` is `https://github.com/pinggu092414/day4-cafe.git`.

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
- Home is a section inside `index.html` itself, not an iframe page. It is rebuilt from Supabase every time it is shown: four cards (today's sales and order count, average review rating, number of menus with stock at or below 5) and a 7-day sales bar chart drawn with plain DOM. The AI briefing from `PRD.md` is not there yet.
- "Today" on the home page is Korea time (UTC+9, no DST) regardless of the browser's time zone. The code does this with UTC arithmetic on `KST`/`DAY` constants rather than local `Date` getters; keep that when changing it. Per-day totals are summed in the browser from `sales?select=amount,sold_at`, so PostgREST's default 1000-row limit would truncate a 7-day window above 1000 sales.
- Pages talk to Supabase with plain `fetch` against the PostgREST endpoint (`<url>/rest/v1/<table>`), sending only the `apikey` header with the publishable key (`sb_publishable_...`, safe to ship in the HTML). There is no client library. The `anon` role has RLS policies and grants on the three tables: full access to `menus` and `sales`, and no DELETE on `reviews`. A sale must go through the Postgres function `public.sell_menu(p_menu_id, p_quantity)` (`POST rpc/sell_menu`, executable by `anon` only), which in one transaction locks the menu row, rejects overselling (`insufficient_stock`, `menu_not_found`, `invalid_quantity`), decrements `menus.stock`, and inserts the `sales` row with `amount = price * quantity`. Never insert into `sales` or patch stock directly from a page, because the REST API cannot do an atomic `stock = stock - n`. `menu.html` is the reference implementation: a PATCH or DELETE blocked by RLS returns an empty array rather than an error, so check the returned rows. Render user-entered text with `textContent`, never `innerHTML`, because anyone holding the key can write rows.
- The visual design follows `DESIGN-composio.md` (kept in the user's Downloads, not in this repo): a dark theme with canvas `#0f0f0f`, cards stepping up in brightness (`#181818`, `#222222`) instead of using shadows, white and `#a8a8a8` text, one accent `--primary` (`#0007cd`) reserved for the brand mark, primary buttons and the radial glow, 8px radius on buttons and nav items, `#222222` hairlines. The design replaced an earlier Airbnb-based light theme. Only the tokens the shell uses are defined as CSS variables in `index.html`'s `:root`; add more from that document as pages need them. `#0007cd` has too little contrast for text on the dark canvas, so use it only as a fill with white text.
- The other pages will be separate documents inside iframes, so they must copy those values and set their own dark `body` background (an unstyled page renders white). Sharing a CSS file instead is still an open decision in `PRD.md`.

## Environment

- Windows 10 with PowerShell 5.1, so `&&` and `||` are not available; chain with `;` or `if ($?) { ... }`.
- Git was installed via winget after this folder was created. A terminal opened before that may not have `git` on its PATH; open a new terminal or refresh `$env:Path`.
- The branch is `main`, pushed to `origin`. Commits in this repo use the repo-local identity `pinggu092414 <pinggu092414@users.noreply.github.com>` so the personal email is not published.
