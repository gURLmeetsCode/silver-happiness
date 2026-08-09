# Deployment notes

The main setup guide is in **[README.md](README.md)** — local development, Raspberry Pi install, systemd, and Tailscale Serve.

## Quick reference

| Step | Command |
|------|---------|
| Health check | `curl -I http://127.0.0.1:3000/up` |
| Start service | `sudo systemctl start silver-happiness` |
| View logs | `journalctl -u silver-happiness -f` |
| Tailscale URL | `tailscale serve status` |
| Restart Serve | `sudo tailscale serve --bg http://127.0.0.1:3000` |
| Regenerate secret | `bin/rails secret` |

**Site down but Pi online in Tailscale?** See [README — Site appears down](README.md#site-appears-down-troubleshooting).

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

## Automated deploy (GitHub Actions) — NOT ACTIVE

> **Deploys are manual today.** Push to `main` runs CI only. Nothing reaches the
> Pi until you run `./bin/deploy` on it.
>
> There is no `.github/workflows/deploy.yml` in this repo. It was removed because
> it required a self-hosted runner that was never registered, so every Deploy run
> sat queued forever and the Actions tab implied the Pi was up to date when it was
> several commits behind. A workflow that silently does nothing is worse than no
> workflow. Follow the steps below to turn it back on.

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

# Pass the user so the service runs as pi, not root
sudo ./svc.sh install pi
sudo ./svc.sh start
sudo ./svc.sh status
```

Confirm it registered — this must list an **active** unit, and the runner must
show as *Idle* on the GitHub Runners page:

```bash
systemctl list-units --all 'actions.runner*'
```

The runner service starts without a login shell, so it does not read `.bashrc`
and may not find Ruby. Check what it will actually see:

```bash
env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin bash -c 'which ruby bundle git'
```

If `ruby` or `bundle` come back empty, hand the runner your real PATH and restart:

```bash
echo "PATH=$PATH" >> ~/actions-runner/.env
cd ~/actions-runner && sudo ./svc.sh stop && sudo ./svc.sh start
```

**3. Restore the workflow**

Recreate `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

concurrency:
  group: deploy-pi
  cancel-in-progress: false

jobs:
  deploy:
    name: Deploy to Raspberry Pi
    runs-on: self-hosted
    # Fail visibly if the runner is offline instead of queueing forever.
    timeout-minutes: 20
    if: >
      github.event.workflow_run.conclusion == 'success' &&
      github.event.workflow_run.head_branch == 'main'

    steps:
      - name: Deploy
        working-directory: /home/pi/silver-happiness
        run: ./bin/deploy

      - name: Diagnose on failure
        if: failure()
        working-directory: /home/pi/silver-happiness
        run: ./bin/doctor || true
```

**4. First deploy**

Push to `main`. Watch **Actions** in GitHub — CI, then **Deploy to Raspberry Pi**.
If Deploy sits at *Queued*, the runner is not connected; fix that before trusting it.

### Manual deploy

**Normal update — one command on the Pi:**

```bash
cd ~/silver-happiness && ./bin/deploy
```

Deploy **refuses to go live** if checks fail, and **rolls back** to the previous commit automatically.

| Gate | When |
|------|------|
| GitHub CI tests + smoke test | Before Pi deploy (push to `main`) |
| `script/production_smoke_test.rb` | On Pi, after migrate, **before** restart |
| HTTP `/up`, `/health`, `/` | On Pi, after restart |
| Rollback | Any check fails — previous code restored + service restarted |

**When something looks wrong:**

```bash
./bin/doctor                    # SSH — logs + HTTP checks
```

**On your phone (bookmark):** `https://raspberrypi.tail57e96f.ts.net/status` — works even when home is 500; shows pending migrations, last error, etc.

Plain `bin/rails` without production env fails on the Pi — use `./bin/pi-rails` for one-off commands.

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
