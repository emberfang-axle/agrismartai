# AgriSmartAI — Batinao Demo (Run Today)

## Quick preview (no Flutter needed)

1. **Start backend** (Terminal 1):
   ```bash
   cd backend
   python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
   ```

   On Windows PowerShell, `python3` may be `python`:
   ```powershell
   cd backend
   python -m uvicorn main:app --host 127.0.0.1 --port 8000
   ```

2. **Open demo page** in Chrome:
   - Open file: `demo/index.html`
   - Or: `start demo\index.html`

3. Test API directly:
   - Health: http://127.0.0.1:8000/health
   - Simulate: http://127.0.0.1:8000/simulate

## Full system (Flutter + Supabase)

### 0. Install Flutter (one-time, required for Android + Web apps)

If `flutter` fails with **"Unable to update Dart SDK"**, run this first:
```powershell
cd c:\Users\PC\OneDrive\Desktop\AgriSmartAI
.\scripts\fix_flutter.ps1
```

Otherwise install Flutter once:

1. Download: https://docs.flutter.dev/get-started/install/windows (stable zip)
2. Extract to `C:\flutter` (not OneDrive — avoids path issues)
3. Add to PATH: `C:\flutter\bin`
4. Open a **new** PowerShell and run:
   ```powershell
   flutter doctor
   flutter config --enable-web
   ```
5. For **Android phone**: enable USB debugging, connect phone, run `flutter devices`
6. For **Android emulator**: open Android Studio → Device Manager → start a virtual device

Then run everything with one script:
```powershell
cd c:\Users\PC\OneDrive\Desktop\AgriSmartAI
.\scripts\run_system.ps1
```

Or manually:

### 1. Supabase (15 min)
Follow `firebase_setup.txt` — create project, run SQL, create `scan-images` bucket, add admin user.

### 2. Set keys
Edit `frontend/farmer_mobile_app/lib/core/config.dart` and `frontend/admin_web_dashboard/lib/core/config.dart`:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- Optional: `DEEPSEEK_API_KEY` for smarter chat

### 3. Mobile app (Terminal 2)
```powershell
cd frontend\farmer_mobile_app
flutter pub get
flutter run
```

### 4. Admin dashboard (Terminal 3)
```powershell
cd frontend\admin_web_dashboard
flutter pub get
flutter run -d chrome
```

## Architecture

```
Mobile App (Flutter) ──► Supabase (Auth, DB, Storage)
        │
        └──► FastAPI Backend (/predict, /chat, /simulate)
Admin Web (Flutter) ────► Supabase
```

## No Firebase
This project uses **Supabase only**. Firebase has been removed.
