# Silver Happiness

A self-hosted fitness and wellness tracker built with Rails. Log meals, workouts, weight, sleep, and progress photos in one place — designed for a single user running on your own hardware.

## Features

- **Today dashboard** — weight, macros, water, sleep, and weekly charts
- **Daily log** — meals (templates or custom), workouts, strength sessions, wellness check-ins, notes
- **Recipes & grocery list** — meal ideas with ingredients grouped by shop section
- **Strength plans** — structured workout templates with optional supplemental sessions
- **Goals** — target weight, protein, calories, and water
- **Photo uploads** — progress and outfit galleries (mobile camera friendly)

No user accounts — intended for private, single-user use on a trusted network.

## Tech stack

Rails 8 · SQLite · Bootstrap 5 (CDN) · Chartkick · Active Storage · Stimulus

---

## Local development

**Requirements:** Ruby 3.3.6, Bundler, ImageMagick (for photo variants)

```bash
git clone https://github.com/gURLmeetsCode/silver-happiness.git
cd silver-happiness
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000)

### Database reset

If migrations fail with foreign-key errors from a partial setup:

```bash
bin/rails db:reset   # drop, create, migrate, seed
```

Use `db:reset` or `db:migrate` — not `db:setup` — once a database file already exists.

### Phone on the same Wi‑Fi

```bash
bin/rails server -b 0.0.0.0
```

Open `http://<your-computer-ip>:3000` from your phone.

### Sync production → local (Mac)

Your Pi has the real logs, meals, and photos. To mirror that on your Mac:

```bash
# One-time: copy .env.sync.example to .env.sync if pi@raspberrypi doesn't work
cp .env.sync.example .env.sync

# Tailscale must be connected on your Mac
bin/sync-from-prod
bin/rails server
```

This pulls `production.sqlite3` into `storage/development.sqlite3` and rsyncs uploaded files from the Pi. Your previous local DB is backed up automatically.

**Requirements:** SSH to the Pi works (`ssh pi@raspberrypi`), and `sqlite3` CLI is installed on the Pi (`sudo apt install sqlite3`).

---

## Raspberry Pi deployment

Run the app on a Raspberry Pi at home and open it from your phone anywhere using [Tailscale](https://tailscale.com) (free personal plan). No public domain or port forwarding required.

### 1. Install system packages

```bash
sudo apt update
sudo apt install -y git build-essential libsqlite3-dev imagemagick curl
```

### 2. Install Ruby 3.3.6 (rbenv)

```bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash
# add rbenv to your shell (~/.bashrc), then:
rbenv install 3.3.6
rbenv global 3.3.6
gem install bundler
```

On older 32-bit Raspberry Pi OS with a 64-bit kernel, Ruby may need:

```bash
RUBY_CONFIGURE_OPTS="--with-coroutine=arm32" rbenv install 3.3.6
```

If the `sqlite3` gem fails to load, rebuild gems for the Pi platform:

```bash
bundle config set force_ruby_platform true
bundle install
```

### 3. Clone and configure the app

```bash
git clone https://github.com/gURLmeetsCode/silver-happiness.git
cd silver-happiness
bundle install

export RAILS_ENV=production
export SECRET_KEY_BASE=$(bin/rails secret)

# Save for future deploys (gitignored)
cat > .env.production <<EOF
RAILS_ENV=production
SECRET_KEY_BASE=${SECRET_KEY_BASE}
EOF
chmod 600 .env.production

bin/rails db:prepare
bin/rails db:seed
bin/rails assets:precompile
```

Production uses SQLite at `storage/production.sqlite3` and ImageMagick (via MiniMagick) for photo resizing — no Node.js or yarn required.

### 4. Run on boot with systemd

Find your bundle path:

```bash
which bundle   # e.g. /home/pi/.rbenv/shims/bundle
```

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
EnvironmentFile=/home/pi/silver-happiness/.env.production
ExecStart=/home/pi/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now silver-happiness
sudo systemctl status silver-happiness
curl -I http://127.0.0.1:3000/up   # expect HTTP 200
```

### 5. Install Tailscale

On the Pi, choose **Linux** when adding a device:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Install Tailscale on your phone (iPhone & iPad) and sign in with the **same account**.

### 6. Expose the app (HTTPS, tailnet only)

Enable [Tailscale Serve](https://tailscale.com/kb/1312/serve) on your tailnet if prompted, then:

```bash
sudo tailscale serve --bg http://127.0.0.1:3000
tailscale serve status
```

Open the URL shown (e.g. `https://raspberrypi.your-tailnet.ts.net`) on your phone with Tailscale connected.

In Safari: **Share → Add to Home Screen** for quick access.

To stop the proxy later:

```bash
tailscale serve --https=443 off
```

### 7. Deploy updates

**Automated (recommended):** set up a [GitHub Actions self-hosted runner](DEPLOY.md#automated-deploy-github-actions) on the Pi once. After that, every push to `main` runs CI and deploys automatically.

**Manual fallback:**

```bash
cd ~/silver-happiness
./bin/deploy
```

### Site appears down (troubleshooting)

In the Tailscale admin, your Pi can show as **online** while the website still fails to load. Tailscale VPN and the web app are **two separate layers**:

```
Phone (Tailscale on) → https://raspberrypi….ts.net → Tailscale Serve → Puma :3000
```

If **Serve** or the **Rails service** stops (common after a Pi reboot), the site is down even though the Pi looks fine in Tailscale.

**On your phone first**

- Open the Tailscale app — confirm it is connected (not paused).
- The `.ts.net` URL only works when your phone is on the same tailnet.
- Try the URL in Safari again (not a stale home-screen bookmark).

**On the Pi (SSH in, then run in order)**

```bash
# 1. Is the Rails app running?
sudo systemctl status silver-happiness

# 2. Does the app respond locally? (expect HTTP 200)
curl -I http://127.0.0.1:3000/up

# 3. Is Tailscale Serve forwarding HTTPS to port 3000?
tailscale serve status

# 4. If the service failed — read the error
journalctl -u silver-happiness -n 50 --no-pager
```

| What you see | Likely cause | Fix |
|--------------|--------------|-----|
| `curl …/up` → **connection refused** but `systemctl` shows running | Puma bound to IPv6 only (`[::]:3000`); Serve uses `127.0.0.1` | Update `config/puma.rb` (production binds `127.0.0.1`), restart service; test `curl -I http://127.0.0.1:3000/up` |
| `curl …/up` → **connection refused** | Puma not running | `sudo systemctl restart silver-happiness` · `journalctl -u silver-happiness -n 50` |
| `systemctl status` → **failed** | Crash after deploy, migration, or config | Check `journalctl`; then `cd ~/silver-happiness && ./bin/deploy` |
| App OK locally (`200` on `/up`), URL still dead | **Tailscale Serve** stopped | `sudo tailscale serve --bg http://127.0.0.1:3000` |
| URL doesn’t load on phone only | Tailscale off on phone, or MagicDNS disabled | Connect Tailscale; enable MagicDNS in the tailnet admin |

**Quick recovery (most common after reboot)**

```bash
cd ~/silver-happiness
./bin/deploy                                    # optional: if you also need code/db updates
sudo tailscale serve --bg http://127.0.0.1:3000
tailscale serve status
curl -I http://127.0.0.1:3000/up              # expect HTTP 200
```

Then open `https://raspberrypi.your-tailnet.ts.net/` on your phone with Tailscale connected.

See also [DEPLOY.md](DEPLOY.md) for service commands and deploy notes.

---

## Security & backups

- **No authentication** — only expose the app on a private network (e.g. Tailscale). Do not publish it to the open internet without adding auth.
- **Back up regularly:** `storage/production.sqlite3` and uploaded files under `storage/`.

```bash
# from your Mac
scp pi@raspberrypi:~/silver-happiness/storage/production.sqlite3 ~/Backups/
```

---

## Project layout

| Path | Purpose |
|------|---------|
| `app/models/daily_log.rb` | One row per day — weight, wellness, summary |
| `app/models/meal_template.rb` | Saved meals for quick logging |
| `app/models/recipe.rb` | Recipes and ingredients |
| `app/models/workout_plan.rb` | Workout plan templates |
| `config/grocery_staples.yml` | Default grocery staples |
| `db/seeds/` | Seed data (products, templates, recipes) |

---

## License

See repository license. Use and modify for your own self-hosted setup.
