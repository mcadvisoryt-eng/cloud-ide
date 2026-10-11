# Running on Google Cloud Shell — the no-card path

Google Cloud Shell is the most reliable free option that needs **no credit card** — just a Google
account. You get a real Linux VM you reach from the browser, with a **persistent 5 GB `$HOME`**, and
it comes pre-loaded with git, Docker, Python, Node, Go, Java and more.

The catch, stated plainly: it is **not always-on**. It terminates an idle session, caps a single
session, and has a weekly quota. Those are the trade-offs for "no card".

| Limit | Value |
|---|---|
| Idle timeout | the VM stops after ~40 minutes of inactivity (a session ends after ~1 h idle) |
| Max session length | 12 hours, then it recycles (start a new one immediately) |
| Weekly quota | ~50 hours per user (resets weekly) |
| Persistent storage | 5 GB at `$HOME`, survives VM recycling |
| Deletion | `$HOME` is deleted after 120 days of no use (start a session to reset the clock) |
| Card required | **No** |

## 1. First-time setup

Open <https://shell.cloud.google.com>, sign in, then:

```bash
git clone https://github.com/<you>/cloud-ide.git
cd cloud-ide
bash scripts/setup.sh             # install code-server, print your password
bash scripts/enable-autostart.sh  # optional: run bootstrap on every future session
bash scripts/bootstrap.sh         # install extensions, apply settings, start
```

`bootstrap.sh` is the one script that does everything. It is idempotent, so you can re-run it any
time without harm.

## 2. Open it in the browser

In the Cloud Shell toolbar, click **Web Preview** → **Change port** → **8080**. A new tab opens with
VS Code; enter your password.

> If the preview ever misbehaves with the editor's live connection, use the stable-URL option in
> section 6 instead — it is more robust.

## 3. Auto-start on every session

You do **not** want to re-run setup by hand each time the VM recycles. `enable-autostart.sh` handles
it by adding a guarded block to `~/.bashrc` that runs `bootstrap.sh` **once per boot**, in the
background:

```bash
bash scripts/enable-autostart.sh
```

That is the recommended method — it runs as you, with the right `$HOME`, and never blocks your shell.
Logs go to `~/.cloud-ide/bootstrap.log`.

**Advanced alternative — `~/.customize_environment`.** Cloud Shell also runs a script at
`~/.customize_environment` on each new VM boot, *as root*. It is useful if you want the IDE up before
a shell is opened, but you must invoke bootstrap as your own user, e.g.:

```bash
#!/bin/bash
# ~/.customize_environment  (Cloud Shell runs this as root on each new VM)
su - "$(id -un 1000)" -c 'cd ~/cloud-ide && bash scripts/bootstrap.sh' &
```

(Adjust the username if it isn't uid 1000.) The `.bashrc` method above is simpler and usually enough.

## 4. What persists, and what doesn't

**Persists (lives in `$HOME`):**
- Your projects, files and Git repos.
- The code-server install (`~/.local`), its extensions (`~/.local/share/code-server`) and config.
- Your VS Code data — settings, keybindings, snippets, extension state.
- Your shell config (`.bashrc`, `.gitconfig`, etc.).

**Does NOT persist (system locations are wiped on recycle):**
- Anything you `apt install` (`/usr`, `/etc`). So don't rely on `sudo apt install nodejs` — use the
  preinstalled tools (which are always present anyway) or per-user toolchains under `$HOME`
  (`config/toolchains.txt` + `scripts/install-toolchains.sh`, which uses mise).

## 5. Extensions and your VS Code data

- **Extensions** come from [`../config/extensions.txt`](../config/extensions.txt). Edit it and run
  `bash scripts/install-extensions.sh`. code-server installs from **Open VSX**, so Microsoft-exclusive
  extensions (Pylance, C# Dev Kit) aren't available there; the installer skips anything it can't find.
- **Save your data** at any time: `bash scripts/backup.sh` writes a snapshot (settings, keybindings,
  snippets, extension list) to `~/.cloud-ide/backups`, keeping the last 5.
- **Restore it**: `bash scripts/restore.sh` brings back the newest snapshot and reinstalls its
  extensions. `bootstrap.sh` calls this automatically when it finds a fresh home.
- **Off-box copy**: set `CLOUDIDE_GIT_REMOTE` to a private repo and `backup.sh` will also push there.

## 6. A stable URL with Tailscale Funnel (still free, still no card)

Web Preview works, but its URL is tied to your session. For a stable `https://…` address, run
code-server behind **Tailscale Funnel** (Tailscale is free and needs no card):

```bash
# Install Tailscale (userspace mode works in Cloud Shell, no root networking needed)
curl -fsSL https://tailscale.com/install.sh | sh

# Bring it up — follow the printed URL to log in once
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &
sudo tailscale up --authkey=<YOUR_TAILSCALE_AUTHKEY>

# Expose code-server publicly over HTTPS
tailscale funnel 8080
```

Tailscale prints a `https://<machine>.<tailnet>.ts.net/` URL you can open from any browser, on any
device. The URL is stable; the underlying Cloud Shell VM still obeys the limits above, so when the
session has ended you start a new one and autostart brings the IDE back.

## 7. Reducing idle termination

You can't remove Cloud Shell's limits, but you can make a session less likely to drop while you are
reading rather than typing:

```bash
# every 4 minutes, poke the shell so it doesn't look idle (runs until the session ends)
while true; do printf '.'; sleep 240; done
```

This is a nudge, not a guarantee — the weekly quota is a hard cap regardless.

## 8. Troubleshooting

- **Editor won't load over Web Preview, or live updates keep dropping.** Some proxies mangle the
  editor's websocket. Use the Tailscale Funnel URL (section 6) — it is the robust path.
- **An extension didn't install.** It's probably not on Open VSX. Check the ID; the installer prints
  which ones failed.
- **`code-server` exits with a JavaScript heap out-of-memory error.** Rare, and only on a very small
  host; cap the heap with `NODE_OPTIONS=--max-old-space-size=512 code-server`. Cloud Shell has ample
  RAM and normally doesn't need this.
- **Port 8080 already in use.** Something else grabbed it. Run `bash scripts/stop.sh`, or set a
  different port: `CODE_SERVER_PORT=8081 bash scripts/setup.sh`, then point Web Preview at 8081.
- **Lost your password.** It is in `~/.config/code-server/config.yaml` (`cat` it), or set a new one:
  `CODE_SERVER_PASSWORD=YourNewPass bash scripts/setup.sh`.

## Quick reference

```bash
bash scripts/setup.sh             # one-time install
bash scripts/enable-autostart.sh  # run bootstrap on every session
bash scripts/bootstrap.sh         # provision + start (safe to re-run)
bash scripts/backup.sh            # snapshot VS Code data
bash scripts/restore.sh           # restore newest snapshot
bash scripts/start.sh             # start only
bash scripts/stop.sh              # stop
cat ~/.config/code-server/config.yaml   # your password
```
