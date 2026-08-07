# Deployment notes

The main setup guide is in **[README.md](README.md)** — local development, Raspberry Pi install, systemd, and Tailscale Serve.

## Quick reference

| Step | Command |
|------|---------|
| Health check | `curl -I http://127.0.0.1:3000/up` |
| Start service | `sudo systemctl start silver-happiness` |
| View logs | `journalctl -u silver-happiness -f` |
| Tailscale URL | `tailscale serve status` |
| Regenerate secret | `bin/rails secret` |

## Home Wi‑Fi only (no Tailscale)

For a quick LAN test without Tailscale:

```bash
RAILS_ENV=production bin/rails server -b 0.0.0.0 -p 3000
```

Open `http://<pi-local-ip>:3000` from a device on the same network. This does not work away from home.

## Custom domain (optional)

If you want a public hostname instead of Tailscale:

1. Use **Cloudflare Tunnel** or similar — no router port forwarding
2. **Add authentication** before exposing health data to the internet

## What `db:seed` loads

Example products, meal templates, workout plans, and recipes to get started. Re-running seed updates baseline records; data you add in the app is preserved.

```bash
RAILS_ENV=production bin/rails db:seed
```

---

## Automated deploy (GitHub Actions)

Push to `main` → CI runs tests → Pi deploys itself. No manual `git pull` after the one-time setup below.

### Why a self-hosted runner?

The Pi is only reachable on your Tailscale network. GitHub’s cloud runners cannot SSH to it directly. A **self-hosted runner** on the Pi polls GitHub outbound and runs `./bin/deploy` when CI passes.

### One-time setup on the Pi

**1. Allow deploy script to restart the service without a password**

```bash
sudo visudo -f /etc/sudoers.d/silver-happiness
```

Add:

```
pi ALL=(ALL) NOPASSWD: /bin/systemctl restart silver-happiness
```

**2. Install the GitHub Actions runner**

On GitHub: **Settings → Actions → Runners → New self-hosted runner → Linux → ARM64**

Then on the Pi:

```bash
mkdir -p ~/actions-runner && cd ~/actions-runner

# Paste the curl + tar commands from GitHub (version changes — use the URL shown in the UI)
# Example shape:
# curl -o actions-runner-linux-arm64-2.xxx.tar.gz -L https://github.com/actions/runner/releases/download/v2.xxx/actions-runner-linux-arm64-2.xxx.tar.gz
# tar xzf ./actions-runner-linux-arm64-2.xxx.tar.gz

./config.sh --url https://github.com/gURLmeetsCode/silver-happiness --token YOUR_TOKEN_FROM_GITHUB

sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

The runner must stay online (systemd service handles this after `svc.sh install`).

**3. First deploy**

Push to `main`. Watch **Actions** in GitHub — CI, then **Deploy to Raspberry Pi**.

### Manual deploy (fallback)

Requires `.env.production` with `SECRET_KEY_BASE` (see README). Then:

```bash
cd ~/silver-happiness
./bin/deploy
```

### Alternative: SSH deploy from GitHub cloud

Possible with [Tailscale in CI](https://tailscale.com/kb/1278/tailscale-github-action) so the cloud runner joins your tailnet briefly, then SSHs to the Pi. More moving parts (Tailscale auth key, SSH key secrets). The self-hosted runner is simpler for a single home Pi.

---

## Sync production → local (Mac)

After logging meals and photos on your phone, pull that data to your Mac for development:

```bash
bin/sync-from-prod
```

See [README.md](README.md#sync-production--local-mac) for setup (`.env.sync`, Tailscale, SSH).

**One-way:** prod → local only. Deploy code with `git push` / `./bin/deploy` on the Pi — never copy `development.sqlite3` back to production unless you mean to overwrite your live data.
