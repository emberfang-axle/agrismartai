# AgriSmartAI

**AI-Powered Rice Crop Disease Monitoring** — New Bataan, Davao de Oro, Philippines

---

## Project structure (organized)

```
AgriSmartAI/
├── frontend/
│   ├── mobile_app/          # Farmer Flutter app (Android / iOS / Web)
│   └── admin_dashboard/     # Admin Flutter Web dashboard
├── backend/                 # Python HTTP API (detection + local AI chat)
├── ai_model/                # Our own AI (no ChatGPT/DeepSeek APIs)
│   ├── simulate_detection.py   # MobileNetV2 disease detection (simulated / trainable)
│   ├── agrismart_chat.py       # Local conversational AI (QA knowledge engine)
│   ├── train_model.py          # Train real MobileNetV2 when dataset is ready
│   └── knowledge/qa_pairs.json # Chat knowledge base
├── postgresql/              # PostgreSQL schema + seed (via backend)
└── scripts/                 # start-dev.ps1, stop-dev.ps1
```

### Why `frontend/` has two apps (not one folder)

| Folder | Who uses it | Purpose |
|--------|-------------|---------|
| `frontend/mobile_app` | **Farmers** | Scan rice leaves, view results, chat assistant, DA locator |
| `frontend/admin_dashboard` | **DA technicians / admins** | Verify reports, view analytics, manage farmers |

Both are Flutter frontends but serve **different users** with **different UIs**. Keeping them as siblings under `frontend/` is cleaner than mixing farmer screens and admin screens in one app.

There is **no separate root `web_dashboard`** anymore — it was merged into `frontend/admin_dashboard`.

---

## Our own AI (no external LLM APIs)

| Feature | Module | How it works |
|---------|--------|--------------|
| Disease detection | `ai_model/simulate_detection.py` | MobileNetV2-style classifier (simulated for defense; train with `train_model.py`) |
| Chat assistant | `ai_model/agrismart_chat.py` | Keyword-scored QA pairs + disease context — works like a chatbot without ChatGPT/DeepSeek |

**DeepSeek and all third-party LLM APIs have been removed.**

---

## Quick start

### 1. Stop old servers (fixes port 8080/8081 errors)

```powershell
.\scripts\stop-dev.ps1
```

### 2. Start everything

```powershell
.\scripts\start-dev.ps1
```

| Service | URL |
|---------|-----|
| Backend API | http://localhost:8000/docs |
| Admin dashboard | http://localhost:8080 |
| Farmer app | http://localhost:8081 |

**Important:** Run `.\scripts\start-dev.ps1` first and wait until it prints **OPEN THESE URLs** (2–3 min on first run).  
`ERR_CONNECTION_REFUSED` means the servers are not started yet.

Check status anytime: `.\scripts\check-dev.ps1`

**Demo login:** Admin `admin@agrismartai.ph` / `admin123` — Farmer: any email/password.

### 3. PostgreSQL database

```powershell
createdb agrismartai
psql -d agrismartai -f postgresql/schema.sql
```

Set `DATABASE_URL` in `backend/.env` (see `backend/.env.example`), then start the API.

**Defense tomorrow:** see [DEFENSE_TOMORROW.md](DEFENSE_TOMORROW.md)

---

## Objectives (in code comments)

1. Collect images from New Bataan  
2. 85%+ accuracy model  
3. App + fertilizer + DA referral  
4. Farmer evaluation + admin dashboard  

---

## Design

- Colors: `#0B3B1F` (Deep Green) + `#D4A017` (Warm Gold)  
- Fonts: Poppins + Inter  
