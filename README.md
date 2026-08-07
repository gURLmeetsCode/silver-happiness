# Silver Happiness

A personal fitness and wellness tracker built for one person — you. It helps you log training, food, body progress, and how you feel day to day, without the noise of a generic calorie app.

Runs on your Mac for development, or on a **Raspberry Pi at home** so you can open it from your iPhone (see [DEPLOY.md](DEPLOY.md)).

---

## What it does

### Dashboard
Your at-a-glance home screen for **today**: weight, protein, calories eaten vs burned, water, sleep, period, and how you’re feeling. Weekly charts show weight vs target, calories, and protein trends.

### Daily log
One page per day where you track everything:

- **Weight** (including pre-run weigh-ins)
- **Meals** — one-tap from saved templates, custom entries, or products with auto-calculated macros
- **Copy yesterday** — repeat boring, predictable meals fast
- **Workouts** — runs, walks, and other activities with distance and calories
- **Strength sessions** — log home, gym, or Runna app workouts with exercises, weights, and difficulty
- **Wellness check-in** — period, water intake, bed/wake time, sleep quality, mood tags (bloated, light, tired, etc.), and daily notes
- **Progress photos** — front/side body shots
- **Outfit snaps** — workout fits, everyday clothes, *Feeling cute*, and *Not as bad as you think*

### Recipes & grocery
A **Recipes** tab with your regular meals (run-day oats, yogurt breakfast, power salad lunch, dinner templates) plus suggested swaps. Each recipe lists ingredients by shop section and step-by-step instructions.

The **Grocery list** combines weekly staples with ingredients pulled from your regular recipes — useful before a shop run. Includes a Sunday batch-prep checklist (tofu, quinoa, dressing).

Recipes linked to meal templates can be logged in one tap on your daily page.

### Strength plans
**Runna handles Wed/Sat strength** — the app treats those as log-only templates after you finish in the app.

**Supplemental suggestions** are extra toning on top of Runna:

| Day type | What’s suggested |
|---|---|
| Mon & Thu | Full home toning session (~30–35 min) |
| Run days (Tue, Fri, Sun) | Optional quick add-on after your run (core, glute+core) |
| Wed & Sat (Runna strength) | Optional quick add-on only |

You can log any plan on any day — suggestions are a nudge, not a rule.

### Goals
Editable targets that drive charts and status badges:

- Target weight, starting weight, target date
- Daily protein min/max
- Calories for training vs rest days
- Daily water goal

### Outfit gallery
A separate gallery for outfit photos by category — workout, everyday, feeling cute, reality check — with optional notes and dates.

---

## Tech stack

- **Rails 8** + SQLite
- **Bootstrap 5** (CDN)
- **Chartkick** + Chart.js for charts
- **Active Storage** for photo uploads
- **Stimulus** for small UI interactions (meal calculator, feeling tags)

No account system — this is a private, single-user app.

---

## Setup (local)

```bash
cd silver-happiness
bundle install
yarn install --ignore-engines
bin/rails db:reset    # first run: drop + create + migrate + seed
bin/dev
```

Open [http://localhost:3000](http://localhost:3000)

### Database trouble?

If you see `FOREIGN KEY constraint failed` during `db:setup`, the SQLite file already existed from a partial setup:

```bash
bin/rails db:reset
```

**Do not use `db:setup`** after the database already exists — use `db:reset` or `db:migrate` instead.

Re-running `db:seed` updates baseline records; it does not wipe data you add later.

---

## Phone use

- **Same Wi‑Fi:** `bin/rails server -b 0.0.0.0` and open your Mac’s IP from iPhone
- **Anywhere (recommended):** deploy on a Raspberry Pi with **Tailscale** — see [DEPLOY.md](DEPLOY.md)

Photo upload forms use the phone camera for progress and outfit snaps.

---

## Project layout (high level)

| Area | Purpose |
|---|---|
| `app/models/daily_log.rb` | One row per day — weight, wellness, training summary |
| `app/models/meal_template.rb` | Saved meals for one-tap logging |
| `app/models/recipe.rb` | Recipes + ingredients for shopping |
| `app/models/workout_plan.rb` | Runna reference + supplemental strength plans |
| `config/grocery_staples.yml` | Weekly shop list (editable) |
| `db/seeds/` | Structure, baseline data, recipes |

---


## Hosting

See **[DEPLOY.md](DEPLOY.md)** for Raspberry Pi + Tailscale setup (free private access from your phone, no domain required).
