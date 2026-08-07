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
