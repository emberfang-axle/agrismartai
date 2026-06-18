# AgriSmartAI — Rice Disease Detection (Batinao)

**Supabase-only** agricultural AI system for New Bataan farmers.

## Stack
| Layer | Tech |
|-------|------|
| Mobile | Flutter + Riverpod + Supabase |
| Admin | Flutter Web + fl_chart + Supabase |
| Backend | FastAPI (routes / services / core) |
| AI | MobileNetV2-ready + simulation fallback |
| Chat | DeepSeek API + Taglish fallbacks |

## Run today
See **[RUN_DEMO.md](RUN_DEMO.md)** for step-by-step instructions.

**Quick preview:** Open `demo/index.html` after starting the backend.

## Project structure
```
backend/app/          # FastAPI (api/routes, services, core)
frontend/farmer_mobile_app/lib/features/   # Mobile (feature-based)
frontend/admin_web_dashboard/lib/          # Admin panel
demo/index.html       # Browser demo dashboard
firebase_setup.txt    # Supabase setup guide (legacy filename)
```

## Features
- Mobile: Splash, Auth, Home, Camera, Analysis, Results, History, ChatGPT-style AI, DA Locator, Profile
- Admin: Dashboard, Reports, Farmers, Analytics, Settings
- Backend: `/predict`, `/simulate`, `/chat`, `/health`

**No Firebase.** Auth, database, and storage use Supabase only.
