# AgriSmartAI

All user-facing apps live under **`frontend/`**. Shared services live at the repo root.

## Folder map

```
frontend/
  mobile_app/         Farmer app — scan leaves, chat, history, DA locator
  admin_dashboard/    Admin web — verify reports, analytics, farmers list

backend/              Python HTTP REST API
ai_model/             Local AI (detection + chat — no external LLM APIs)
postgresql/           PostgreSQL schema (accessed via Python backend)
scripts/              start-dev.ps1, stop-dev.ps1
```

## Why two frontend apps?

| App | User | Platform |
|-----|------|----------|
| `mobile_app` | Rice farmers in the field | Phone (Android/iOS) + optional web preview |
| `admin_dashboard` | DA staff / researchers | Desktop web browser |

They share the same backend and database but have **different navigation, permissions, and screens**. Merging them into one Flutter project would mix farmer and admin code and make the app harder to maintain.

## Removed / merged (cleanup)

- `frontend/farmer_mobile_app` — old duplicate → replaced by `frontend/mobile_app`
- `frontend/admin_web_dashboard` — old duplicate → replaced by `frontend/admin_dashboard`
- `web_dashboard/` (root) — merged into `frontend/admin_dashboard`
- `mobile_app/` (root) — merged into `frontend/mobile_app`
- `standalone_app/` — removed duplicate
- DeepSeek / ChatGPT APIs — removed; use `ai_model/agrismart_chat.py`

## Run

```powershell
.\scripts\stop-dev.ps1    # free ports 8000, 8080, 8081
.\scripts\start-dev.ps1   # start backend + both apps
```
