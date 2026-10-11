# A full Linux desktop in the browser

code-server gives you VS Code + a terminal. If you want a **whole desktop** — a taskbar, file
manager, browser, terminal windows — you have two good recipes.

Both need a host with **root** and a **real persistent disk**. That means a free no-card VPS
(`docs/alternatives.md`), a machine you own, or Oracle Cloud later. You **cannot** do this inside
Cloud Shell alone, because a desktop is installed to system paths (`/usr`, `/etc`) that Cloud Shell
does not persist — only `$HOME` survives there.

---

## Option A — XFCE + TigerVNC + noVNC (lightweight, works anywhere with root)

This runs a small XFCE desktop, exports it over VNC, and serves a browser client (noVNC) on a port
you can reach.

```bash
sudo apt update
sudo apt install -y xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common \
                    novnc websockify dbus-x11

# Set a VNC password (8 chars max) and a read-only is optional
vncpasswd

# Minimal startup file: launch XFCE inside the VNC session
cat > ~/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x ~/.vnc/xstartup

# Start a desktop on display :1, listening only on localhost
vncserver :1 -geometry 1280x720 -localhost yes

# Serve noVNC on port 6080, bridged to the VNC display
websockify --web=/usr/share/novnc/ 6080 localhost:5901
```

Open `http://<host>:6080/vnc.html`, connect to display `:1`, and you have a full desktop.

**Keep it running** (so it survives logout) with a small systemd unit, or `nohup`:

```bash
nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 >~/novnc.log 2>&1 &
```

Put it behind a password or a tunnel — an open noVNC port is a full remote control of the host.

---

## Option B — LinuxServer.io *webtop* container (heavier, but everything is pre-wired)

The LinuxServer.io **webtop** image ships a complete desktop (KDE, XFCE or i3) plus noVNC, and is
reachable purely in the browser. Requires Docker on the host.

```bash
docker run -d \
  --name=webtop \
  -e PUID=1000 -e PGID=1000 \
  -e TZ=Asia/Kolkata \
  -e SUBFOLDER=/ \
  -p 3000:3000 \
  -v /path/to/your/data:/config \
  --shm-size="1gb" \
  --restart unless-stopped \
  lscr.io/linuxserver/webtop:ubuntu-xfce
```

Open `http://<host>:3000`. Your files live in the mounted `/config` volume, so they persist across
container restarts. Swap `ubuntu-xfce` for `ubuntu-kde`, `alpine-i3`, etc.

---

## Which should you pick?

- **Just want to code?** You don't need either — use `scripts/setup.sh` (code-server) and skip this.
- **Want a real desktop on a small VPS?** Option A is lighter and needs no Docker.
- **Want a desktop with everything wired up and you have Docker?** Option B.

## A note on Windows

A genuine Windows desktop needs either a Windows host (a paid Windows VPS) or nested virtualisation
with KVM — neither is available on a free, no-card, always-on host. If Windows specifically is the
goal, the realistic route is Oracle Cloud's Always Free Windows VM, which requires a Visa/Mastercard
at signup. Everything in *this* repo is Linux, which is what you can actually get for free.
