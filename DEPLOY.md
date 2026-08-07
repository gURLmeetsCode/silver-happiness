## What gets seeded in production?

Your **real baseline** — not fake demo data:

- Strength workout plans (Wednesday home, Saturday gym, core, Runna)
- Default goals (edit in app anytime)
- Your products (Koro, Sojasun, oats, protein powder, etc.)
- Meal templates (run breakfast, yogurt breakfast, power salad)
- **Aug 6–7 logs** as they actually happened

Anything you add after deploy stays. Re-running `db:seed` only updates these baseline records.

```bash
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/rails db:seed
```

---

## Tailscale setup — Raspberry Pi = **Linux**

On the Tailscale “add your first device” screen, choose **Linux** (not macOS, not iPhone).

Your Pi runs Raspberry Pi OS = Linux.

### On the Raspberry Pi (SSH or keyboard)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Sign in with the same account as your Mac (**gURLmeetsCode@github**). The Pi appears in your Tailscale admin.

### On your iPhone

Choose **iPhone & iPad** in Tailscale, install the app, sign in with the **same account**.

### Expose Silver Happiness (after app is running on Pi)

```bash
sudo tailscale serve https / http://127.0.0.1:3000
```

Tailscale shows a URL like `https://raspberrypi.your-tailnet.ts.net` — open that on your iPhone.

**Add to Home Screen** in Safari for quick access like an app.

### On your Mac (for admin)

You can use **macOS** in Tailscale too — useful for checking the Pi, but the Pi itself is always **Linux**.

---

## Option A — Tailscale (free, recommended)

Private VPN between your Pi and iPhone. Only your devices can reach the app.

### 1. Install Tailscale

On Pi and iPhone: install from [tailscale.com](https://tailscale.com) (free personal plan).

### 2. Deploy the app on Pi

```bash
# On Raspberry Pi (64-bit OS recommended)
sudo apt update
sudo apt install -y git ruby ruby-dev build-essential libsqlite3-dev nodejs npm

git clone https://github.com/gURLmeetsCode/silver-happiness.git
cd silver-happiness
bundle install
yarn install --ignore-engines
yarn build:css   # if CSS build fails, see README — Bootstrap CDN works in browser

export RAILS_ENV=production
export SECRET_KEY_BASE=$(bin/rails secret)

bin/rails db:prepare
bin/rails db:seed          # workout plans only
bin/rails assets:precompile
```

### 3. Run with systemd (starts on boot)

Create `/etc/systemd/system/silver-happiness.service`:

```ini
[Unit]
Description=Silver Happiness
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/silver-happiness
Environment=RAILS_ENV=production
Environment=SECRET_KEY_BASE=your_secret_here
ExecStart=/usr/bin/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now silver-happiness
```

### 4. Expose via Tailscale Serve (HTTPS, free)

```bash
sudo tailscale serve https / http://127.0.0.1:3000
```

Tailscale gives you a private URL like:

`https://raspberrypi.your-tailnet-name.ts.net`

Open that on your iPhone (with Tailscale connected). **Add to Home Screen** in Safari for an app-like icon.

---

## Option B — Home Wi‑Fi only (free, simplest test)

```bash
RAILS_ENV=production bin/rails server -b 0.0.0.0 -p 3000
```

On iPhone (same Wi‑Fi): `http://192.168.x.x:3000` (Pi’s local IP).

Works at home only — not when you’re out.

---

## Option C — Custom domain (optional, paid)

Only if you want `silverhappiness.yourdomain.com`:

1. Buy domain (Porkbun, Cloudflare, Gandi, etc.)
2. Use **Cloudflare Tunnel** (free) to reach Pi without opening router ports
3. Point DNS to Cloudflare

More setup than Tailscale. Worth it if you want a public URL — but **add password protection** since health data shouldn’t be public.

---

## Security notes

- This app has **no login** yet — fine on a private Tailscale network, risky if exposed to the internet
- **Back up** `storage/production.sqlite3` and `storage/` (photos) regularly
- Pi SD cards fail — copy backups to your Mac weekly:

```bash
scp pi@raspberrypi.local:~/silver-happiness/storage/production.sqlite3 ~/Backups/
```

---

## Updates after git pull

```bash
cd silver-happiness
git pull
bundle install
yarn install --ignore-engines
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails assets:precompile
sudo systemctl restart silver-happiness
```
