# cloud-ide

**A persistent, self-provisioning VS Code + terminal you open in any web browser — on a host that needs no credit card.**

Every time you open a new session it rebuilds itself: installs/refreshes code-server, reinstalls
your extensions, restores your settings, and starts the server — automatically. Your data lives in
`$HOME`, so nothing is lost between sessions, and there is no 6-hour kill and no minute cap.

---

## What you get

- **Real VS Code in the browser** (code-server) with its **integrated terminal**, extensions, Git,
  debugger and file explorer.
- **Auto-provisioning on startup** — one script (`bootstrap.sh`) that is safe to run on every boot,
  plus an optional hook that runs it for you whenever a session starts.
- **A curated extension set installed for you** — edit `config/extensions.txt` and it installs the
  rest on the next boot. Broad language coverage out of the box (Python, Go, Rust, Java, JS/TS, PHP,
  Ruby, shell, YAML, Markdown, Docker…).
- **Your VS Code data saved and restored** — settings, keybindings, snippets, extension state and the
  installed-extension list are snapshotted by `backup.sh` and brought back by `restore.sh`.
- **No card required.** The default path runs on Google Cloud Shell, which you open with nothing but
  a Google account.

## The honest bit

There is no such thing as *free + no card + always-on + persistent + unlimited*. A machine that
never sleeps costs somebody money. Every free tier gives up at least one of those, so be clear about
what you are choosing:

| Host | Card? | Persistence | Auto-stop / limits | Cost | Good for |
|---|---|---|---|---|---|
| **Google Cloud Shell** (default here) | **No** | 5 GB persistent `$HOME` | ~40 min idle timeout, 12 h session cap, **50 h/week quota** | Free | VS Code + terminal, on a Google account |
| A **free no-card VPS** (see `docs/alternatives.md`) | No | Real disk | **None** | Free | A true always-on box — but small and less reliable |
| GitHub Codespaces | No (up to 60 h) | Real disk | **Auto-stop + 60 h/month** | Free tier | GitHub-native dev |
| GitHub Actions (the "cloud-desktop" trick) | No | Snapshot/restore only | **6 h hard kill**, data loss | Free (against ToS) | Demos, nothing you rely on |
| Oracle Cloud Always Free | **Yes** (Visa/MC) | Real disk | None | Free forever | The real deal *if* you have a card |

**So: if "no card, ever" is absolute, you cannot also have "no auto-stop, no quota" on a mainstream
cloud.** Cloud Shell is the most reliable no-card option; it trades the always-on guarantee for its
idle timeout and weekly quota. If the always-on guarantee matters more, a free no-card VPS trades the
other way. Both are covered here.

## Quickstart — Google Cloud Shell (no card)

1. Open <https://shell.cloud.google.com> and sign in with any Google account. No billing, no card.
2. In the terminal that opens:

   ```bash
   git clone https://github.com/<you>/cloud-ide.git
   cd cloud-ide
   bash scripts/setup.sh             # install code-server, print your password
   bash scripts/enable-autostart.sh  # optional: auto-run on every future session
   bash scripts/bootstrap.sh         # install extensions, apply settings, start
   ```

3. Click **Web Preview** in the Cloud Shell toolbar → **Change port** → **8080**.
4. Log in with the password `setup.sh` printed. You now have VS Code + a terminal in the browser,
   with your extensions and settings already in place.

After `enable-autostart.sh`, you never repeat this — every new session brings the IDE up by itself.

## How startup works

`scripts/bootstrap.sh` is the single entry point. It is idempotent, so it is safe on every boot, and
it does, in order:

1. **Ensure code-server** — installs it into `$HOME` if missing.
2. **Restore** saved VS Code data — only if the home is fresh (so it never overwrites live data).
3. **Seed settings/keybindings** — copies the repo defaults in, without clobbering your own edits.
4. **Install extensions** — everything in `config/extensions.txt`, skipping what's already there.
5. **Optional toolchains** — only if you uncomment entries in `config/toolchains.txt`.
6. **Start code-server.**

`scripts/enable-autostart.sh` adds a guarded block to `~/.bashrc` that runs `bootstrap.sh` **once per
boot**, in the background, so it never blocks your shell. (On Cloud Shell you can alternatively wire
it into `~/.customize_environment`; see `docs/cloud-shell.md`.)

## Extensions

The list lives in [`config/extensions.txt`](config/extensions.txt) — one `publisher.name` per line.
Add or remove freely and re-run:

```bash
bash scripts/install-extensions.sh
```

code-server installs from **Open VSX** (the open registry), so a few Microsoft-exclusive extensions
(Pylance, C# Dev Kit) aren't available there — they're listed commented at the end of the file. The
installer is tolerant: any ID that fails is reported and skipped, never fatal.

## Saving and restoring your VS Code data

Two layers:

- **Native (automatic).** On Cloud Shell, `$HOME` persists, so your settings, keybindings, snippets
  and extensions are simply *there* next session — nothing to do.
- **Explicit snapshots.** For safety, or to move to another host:

  ```bash
  bash scripts/backup.sh    # snapshot to ~/.cloud-ide/backups (keeps the last 5)
  bash scripts/restore.sh   # restore the newest snapshot + reinstall its extensions
  ```

  A snapshot contains code-server's `User` data (settings, keybindings, snippets, global/workspace
  storage) and the installed-extension list. Extension *binaries* aren't archived — restore
  reinstalls them from the list, which is far smaller. Your password is **not** in the archive (it
  stays in `~/.config/code-server/config.yaml`).

  To also copy snapshots off-box, point `CLOUDIDE_GIT_REMOTE` at a private git repo (free, no card):

  ```bash
  export CLOUDIDE_GIT_REMOTE="https://<token>@github.com/<you>/cloud-ide-backups.git"
  bash scripts/backup.sh
  ```

`bootstrap.sh` also snapshots your data automatically on each session start (set
`CLOUDIDE_AUTOBACKUP=0` to disable), so a recent backup always exists without you thinking about it.

## Access options

- **Web Preview** — instant, built into Cloud Shell (proxies ports 8080–8084).
- **Tailscale Funnel** — a stable public `https://…` URL, still free and no-card. See
  `docs/cloud-shell.md`.

## Want a full desktop, not just an IDE?

See **[`docs/full-desktop.md`](docs/full-desktop.md)** — an XFCE + noVNC desktop, or the
LinuxServer.io *webtop* container. This needs a host with root (a free no-card VPS, or Oracle later).

## On a phone (Termux / Android)

code-server does not fully support Android, so it refuses server-side extensions there — that is why
every extension fails if you run it in plain Termux. The reliable fix is to run it inside
`proot-distro` Ubuntu on the phone, where extensions work normally; a bundled platform shim is also
included as a fallback. Full guide: **[`docs/termux.md`](docs/termux.md)**.

## Why not GitHub Actions?

The popular "Windows/Android desktop on GitHub Actions" projects run on **ephemeral** runners with a
**6-hour hard kill**, lose data between snapshots, and are **off-label use of Actions**. That is
exactly the auto-stop-and-limited behaviour to avoid. This project puts the IDE on a **persistent
host** instead, so there is no kill clock and nothing to rebuild from scratch.

## Files

```
README.md
config/
  extensions.txt          extensions installed on startup
  settings.json           default VS Code settings (seeded, never clobbering yours)
  keybindings.json        default keybindings
  toolchains.txt          optional extra toolchains (mise), empty by default
scripts/
  setup.sh                install code-server into $HOME
  bootstrap.sh            the one-command provision + start (run on every boot)
  apply-config.sh         seed settings/keybindings
  install-extensions.sh   install config/extensions.txt, idempotently
  install-toolchains.sh   optional toolchains via mise
  backup.sh               snapshot VS Code data + extension list
  restore.sh              restore the newest snapshot
  enable-autostart.sh     wire bootstrap into ~/.bashrc (once per boot)
  android-as-linux.js     platform shim so Termux/Android installs extensions
  start.sh / stop.sh      run / stop code-server
docs/
  cloud-shell.md          the no-card path, step by step (+ autostart, stable URL)
  termux.md               running it on a phone (Termux/Android)
  full-desktop.md         a full Linux desktop in the browser
  alternatives.md         free no-card VPS options, and the trade-offs
```

## Security

No secrets live in this repo. The code-server password is generated locally on first run and stored
in `~/.config/code-server/config.yaml` (mode `600`); it is deliberately excluded from backups. Never
expose code-server without its password — its terminal can fully control the host.

## License

MIT.
