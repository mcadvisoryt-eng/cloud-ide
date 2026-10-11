# Other no-card hosts, and the trade-offs

Cloud Shell is the default because it is reliable and genuinely needs no card. But it auto-stops and
has a weekly quota. If "always on, no time limit" matters more to you than reliability, here is the
rest of the landscape.

## The rule

Free + no card + always-on + persistent + unlimited does not exist as a managed service. The machine
has to be paid for by someone. Every option below gives up one of those five — the table tells you
which.

| Option | Card? | Always-on? | Persistence | Watch out for |
|---|---|---|---|---|
| **Google Cloud Shell** | No | No (idle timeout, 50 h/week) | 5 GB `$HOME` | The default in this repo |
| **Free no-card VPS** | No | **Yes** | Real disk | Tiny disks, unverified providers, reliability |
| **Oracle Cloud Always Free** | **Yes** (Visa/MC) | **Yes** | Real disk (200 GB) | Card required; RuPay/prepaid rejected |
| **Joy.services** | No (UPI/phone) | Yes | Real disk | Starter credit is a *trial*, not forever |
| **GitHub Codespaces** | No (up to 60 h) | No | Real disk | Auto-stop + 60 h/month cap |
| **GitHub Actions trick** | No | No | Snapshots only | 6 h kill, data loss, against ToS |

## Free no-card VPS — the "always on" option

A handful of small providers offer a genuinely free tier with **no card**, verified by email, a
GitHub profile, or a student/company email. They give you a real always-on Linux box with root — so
you get *no auto-stop and no minute limits* — but the resources are tiny and the providers are not
the big clouds.

Typical free tiers look like **1 vCPU, ~1–2 GB RAM, and 500 MB–6 GB of disk**, Linux only.

```bash
# On such a box, the whole thing is:
git clone https://github.com/<you>/cloud-ide.git && cd cloud-ide
bash scripts/setup.sh
bash scripts/start.sh
# then open http://<your-vps-ip>:8080  (put it behind Tailscale or a password)
```

Because disk is small, prefer code-server (an IDE, ~a few hundred MB) over a full desktop, and keep
heavy toolchains minimal.

### Treat "free VPS" sites with real caution

- **Many are honeypots, crypto-miners, or data collectors.** The ones that ask only for an email and
  then want you to run their "agent" are the dangerous kind.
- **"Free forever" often means a short trial** that quietly expires, or a tier that gets discontinued.
- **Never run an unknown provider's script as root**, and never reuse a password you care about.
- Prefer providers that verify with a **GitHub profile or a student email** and clearly state the
  free tier's limits in writing.

## If you can ever get a Visa/Mastercard

**Oracle Cloud Always Free** is the real prize: a permanent free VM (currently ~2 ARM cores, ~12 GB
RAM, ~200 GB disk) in the **Mumbai or Hyderabad** region, always-on, with a real disk — the "whole
OS, no auto-stop, no limits" answer. The only blocker is that Oracle requires a Visa or Mastercard
for identity verification (a small refundable hold). RuPay, prepaid and virtual cards are rejected.
If you can borrow a family member's card for the one-time check, this becomes your best option; the
`docs/full-desktop.md` recipes apply directly to it.

## Why not GitHub Actions?

The widely-shared "Windows/Android desktop on GitHub Actions" projects are clever, but:

- runners are **ephemeral** — every run is a brand-new machine;
- there is a **6-hour hard kill**, and anything changed since the last snapshot is lost;
- it is **off-label use of Actions** — the terms say hosted runners are for building/testing the
  repo's software, and enforcement can cost you the repo or account.

That is the exact auto-stop-and-limited behaviour to avoid, so this project doesn't use it.

## Why not Codespaces?

Codespaces is polished and GitHub-native, but the free tier is **60 hours/month** and it **auto-stops**
on idle — the same limits you wanted to escape. It's a fine tool; it just isn't "no limits".
