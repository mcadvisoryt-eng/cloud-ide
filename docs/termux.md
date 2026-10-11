# Running on a phone — Termux / Android

Short version: **code-server does not fully support Android**, and the *reason extensions fail* is
documented by the project itself — on Android it only allows "web" extensions and refuses the rest.
There is no clean fix inside plain Termux, so for a real IDE you want a Linux userspace on the phone.

If your `install-extensions.sh` run printed `failed` for every extension, that is this — not a bug in
this repo.

---

## Why it happens

code-server detects the platform as `android` and treats it as unsupported, so it will only install
extensions marked "web". Everything else is refused. The upstream docs list the fix as *none*, with
workarounds below.

Two related gotchas:

- The generic installer (`curl code-server.dev/install.sh | sh`) falls back to a **standalone glibc
  build** on Termux. Termux uses a different libc (bionic), so that build is not what the project
  recommends for Android.
- The **supported** way to get code-server on Termux is the Termux User Repository package:
  `pkg install tur-repo && pkg install code-server`.

---

## Route A — proot-distro Ubuntu (recommended: extensions just work)

Run a real Ubuntu userland inside Termux with `proot-distro` (no root needed). Inside it, code-server
behaves like it does on any Linux box, so extensions install normally.

```bash
# In Termux (install it from F-Droid, not the Play Store)
pkg update && pkg upgrade -y
pkg install proot-distro -y
proot-distro install ubuntu
proot-distro login ubuntu --shared-tmp --termux-home
```

You are now inside Ubuntu. Install and start code-server:

```bash
apt update && apt install -y curl
curl -fsSL https://code-server.dev/install.sh | sh
code-server --bind-addr 127.0.0.1:8080
```

Then open `http://localhost:8080` in your phone's browser. `proot-distro` shares the network with
Termux, so localhost reaches it. Files under `~/` are shared with Termux via `--termux-home`.

Extensions now install normally — you can point this repo's `install-extensions.sh` at the Ubuntu
code-server, or just use the Extensions view.

**Keep it alive:** Android aggressively kills background work. Use a wake lock and start it on boot:

```bash
termux-wake-lock              # keep the CPU awake
# Optional: install Termux:Boot from F-Droid, then
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/code-server.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
proot-distro login ubuntu --shared-tmp --termux-home -- \
  bash -lc 'code-server --bind-addr 127.0.0.1:8080' &
EOF
chmod +x ~/.termux/boot/code-server.sh
```

Also set Android Settings → Apps → Termux → battery → **unrestricted**, or the OS will still kill it.

---

## Route B — native Termux, with the platform shim

If you would rather stay in plain Termux, the documented workaround is to make code-server *pretend*
to be Linux. This repo ships the shim at `scripts/android-as-linux.js`, and
`scripts/install-extensions.sh` loads it automatically when it detects Termux.

To use it by hand (for the server and the CLI):

```bash
# Supported install, not the generic script:
pkg install tur-repo -y
pkg install code-server -y

# Start with the shim so extensions install
NODE_OPTIONS="--require $HOME/cloud-ide/scripts/android-as-linux.js" code-server --bind-addr 127.0.0.1:8080
```

Then run `bash scripts/install-extensions.sh` as usual — it picks up the shim on Termux.

⚠️ Android and Linux are not 100% compatible. Extensions with native binaries (some debuggers, some
language servers) may still break. Route A avoids this.

---

## Route C — manual `.vsix`

For any extension the shim can't handle: download its `.vsix` on a computer, copy it to the phone,
then in code-server use **Command Palette → "Extensions: Install from VSIX…"**.

---

## Security on a phone

- **Bind to localhost.** `bind-addr: 127.0.0.1:8080` keeps it private to the phone. This repo's
  `setup.sh` binds `0.0.0.0` by default (fine on Cloud Shell); on Termux set
  `CODE_SERVER_BIND=127.0.0.1:8080` before running it, or edit
  `~/.config/code-server/config.yaml`.
- To reach it from a laptop, prefer an **SSH tunnel** over opening the port to your network:
  `ssh -L 8080:localhost:8080 <phone>`.
- Never expose code-server's port to the internet without TLS and a strong password.

---

## What works, and what this is good for

- **Works:** editing, terminals, Git, most extensions via Route A, a genuinely portable dev box.
- **Limits:** Android may still kill the server when the screen is off or under memory pressure, and
  a phone is not an always-on host the way a small VPS is.

For a truly always-on box, Cloud Shell (`docs/cloud-shell.md`) or a free no-card VPS
(`docs/alternatives.md`) will be more dependable than a phone.
