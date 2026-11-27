<p align="center"><img src="app/icons/waink-logo.svg" width="96" alt="WAiNK logo"></p>

# WAiNK

A single-page, phone-first car scanner. Point your phone at a car, hold **WAiNK IT**, and it identifies the
year / make / model / paint, reads the plate if it's clear, and estimates its value — with a game-style
"sim" card on top.

- **Live viewfinder** with a white WAiNK crosshair, scanning sweep and a green lock-on box (on-device car detection with TensorFlow.js COCO-SSD). Scans only start when a car is boxed.
- **Gemini** (free tier) identifies the car from the exact frame in the viewfinder, with automatic fallback across models.
- **Details pop-up** — the camera is fully released while you read it (the phone's camera indicator turns off), and comes back with *Back to scan*.
- **History** (saved on the device) — swipe left/right on phones, or use the tabs.
- **Sound effects** (Web Audio, toggle in Settings), home-screen install (PWA), works on phones and PC.

## Layout

```
app/                     The app (static files served by nginx)
  index.html             Everything: UI, camera, detection, Gemini calls. Key placeholder: __GEMINI_KEY__
  icons/                 Logo (SVG) + favicon / home-screen / install icons
gate/                    Passcode gate that sits in front of the app on the public domain
  __gate.html            The passcode page
  default.conf.template  nginx config (passcode, login token and domain filled in by install-gate.sh)
cloudflared/             Example Cloudflare Tunnel config (only the gate is exposed)
scripts/
  deploy.sh              Build with your key and upload to the server (keeps old versions as old_N)
  install-gate.sh        Set up the passcode gate on the server
docker-compose.yml       nginx container serving app/ on port 30606
```

## Setup

1. **Gemini key** – get a free key at <https://aistudio.google.com/apikey>.
   Copy `.env.example` to `.env` and fill in `GEMINI_API_KEY`, `DEPLOY_HOST`, `DEPLOY_DIR`.
   `.env` is git-ignored; the key is only written into `dist/` (also git-ignored) at deploy time.
2. **Serve the app** – `docker compose up -d` on the server (or the CasaOS app), serving `DEPLOY_DIR` on port 30606.
3. **Deploy** – `./scripts/deploy.sh` (needs SSH access to the server). The live `index.html` is kept as `old_N`.
4. **Passcode gate** – copy `gate/` and `scripts/install-gate.sh` to the server and run
   `sudo ./scripts/install-gate.sh your-domain.com "your passcode"`. It listens on `127.0.0.1:30607`.
5. **Public domain (optional)** – install `cloudflared`, create a tunnel and use `cloudflared/config.example.yml`
   so the domain points at the gate only. HTTPS is needed for the live camera on phones.

## Security notes

- **Never commit a real Gemini key.** `app/index.html` only contains `__GEMINI_KEY__`.
- Anyone who gets past the passcode can read the key in the page source — keep the passcode private and use a
  separate free-tier key for this app.
- The tunnel exposes only the passcode gate; nothing else on the server is reachable from the internet. (allegedly)

## Notes

- iPhone sounds follow the ringer switch (silent = muted) and mix with music.
- Camera permission: set the site to **Allow** in Safari's website settings so it isn't asked every time. (Beware other websites that might try to use your camera)
- "Sim" values (access, tracker, sell/register) are game flavor; the market value is an AI estimate, not an official Kelley Blue Book price.

Vibe Coded With Claude
