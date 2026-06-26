# AgriSmartAI — Capstone Defense Presentation (15 Slides)

**Project:** AI-Powered Rice Crop Disease Monitoring  
**Location:** New Bataan, Davao de Oro, Philippines  
**Team:** [Your Names]  
**Date:** [Defense Date]

---

## Slide 1: Title
- **AgriSmartAI**
- AI-Powered Rice Crop Disease Monitoring System
- New Bataan, Davao de Oro
- [Team members + adviser name]

**Speaker notes:** Introduce the team and project title. State that this system helps rice farmers detect diseases early.

---

## Slide 2: Problem Statement
- Rice farmers rely on manual visual inspection — slow and inaccurate
- Bacterial Leaf Blight, Rice Blast, and Tungro cause 20–70% yield loss
- Limited access to agricultural technicians in remote barangays
- Delayed diagnosis → wrong fertilizer/treatment → crop failure

**Speaker notes:** Emphasize real-world impact on New Bataan farmers.

---

## Slide 3: Objectives
1. Collect rice leaf images from New Bataan farmers
2. Develop AI model (MobileNetV2) with 85%+ target accuracy
3. Build mobile app with fertilizer recommendations + DA referral
4. Create admin dashboard for report verification
5. Evaluate system usability with farmers

**Speaker notes:** Map each objective to a demo feature.

---

## Slide 4: Scope & Limitations
- **Scope:** 4 disease classes (BLB, Blast, Tungro, Healthy)
- **Platform:** Flutter mobile + Flutter Web admin dashboard
- **Backend:** Python HTTP server + PostgreSQL
- **Limitation:** AI uses simulated MobileNetV2 for capstone defense (training pipeline ready)

**Speaker notes:** Be honest about simulation — real training planned with collected dataset.

---

## Slide 5: Technology Stack
| Layer | Technology |
|-------|------------|
| Mobile App | Flutter + Riverpod + image_picker |
| Web Dashboard | Flutter Web + fl_chart |
| Backend API | Python (stdlib HTTP server) |
| Database | PostgreSQL |
| AI | MobileNetV2 (simulated inference) |
| Chatbot | Ka-Agro — local keyword QA engine |

**Speaker notes:** No Supabase/Firebase — pure PostgreSQL as required.

---

## Slide 6: System Architecture
```
Farmer App (Flutter)
    ↓ REST API
Python Backend
    ↓ SQL
PostgreSQL (users, reports, diseases, feedback, chatbot_qa)
    ↓
Admin Dashboard (Flutter Web)
```

**Speaker notes:** Show data flow: upload → detect → save report → admin verifies.

---

## Slide 7: Database Design
- **users** — farmers & admins (UUID, email, password_hash)
- **reports** — scan results (disease_label, confidence, status)
- **diseases** — knowledge base (fertilizer tips, DA referral)
- **feedback** — farmer ratings
- **chatbot_qa** — Ka-Agro Q&A pairs

**Speaker notes:** Show ER diagram or table list from `postgresql/schema.sql`.

---

## Slide 8: AI Disease Detection
- MobileNetV2 transfer learning architecture
- Input: 224×224 RGB rice leaf image
- Output: disease class + confidence score (85–98%)
- **Defense demo:** Simulated inference (deterministic per image hash)
- Training pipeline: `train_model.py` ready for New Bataan dataset

**Speaker notes:** Demo live upload — explain simulation vs. future trained model.

---

## Slide 9: Mobile App Demo — Farmer Flow
1. Login / Register
2. Upload leaf photo from gallery
3. AI analysis (2–5 seconds)
4. View result: disease name, confidence, fertilizer, DA referral
5. Chat with Ka-Agro assistant
6. View scan history

**Speaker notes:** LIVE DEMO — upload a rice leaf image.

---

## Slide 10: Ka-Agro Chatbot
- Offline keyword-matching QA engine (no ChatGPT)
- 15+ seeded Q&A pairs in PostgreSQL
- Answers about: diseases, fertilizer, varieties, DA office, planting/harvest
- Context-aware: uses last scan result for better answers

**Speaker notes:** Demo 3 different questions — show varied responses.

---

## Slide 11: Admin Dashboard
- Command Center with stats cards (farmers, scans, pending reports)
- Disease distribution charts (fl_chart)
- Reports table with **Verify** / **Reject** buttons
- Farmer management & analytics

**Speaker notes:** LIVE DEMO — verify a pending report.

---

## Slide 12: UI/UX Design
- Color palette: Deep Green (#0B3B1F) + Warm Gold (#D4A017)
- Fonts: Poppins + Inter
- Premium cards, confidence meter, animated transitions
- Confirmation dialogs for logout & delete
- Mobile-first, accessible for farmers

**Speaker notes:** Show screenshots if live demo fails.

---

## Slide 13: Testing & Results
| Feature | Status |
|---------|--------|
| UI/UX | 100% complete |
| Gallery upload | Working |
| Simulated AI detection | Working (85–98% confidence) |
| PostgreSQL integration | Working |
| Chatbot | Working (varied responses) |
| Admin verify/reject | Working |

**Speaker notes:** Mention farmer evaluation feedback if available.

---

## Slide 14: Conclusion & Recommendations
- AgriSmartAI successfully integrates AI, mobile, and admin monitoring
- Helps farmers get instant disease guidance + DA referral
- **Next steps:** Collect New Bataan dataset → train real MobileNetV2 → deploy to Play Store
- **Recommendation:** Partner with DA New Bataan for field testing

**Speaker notes:** End with impact statement for local farmers.

---

## Slide 15: Q&A
- **AgriSmartAI**
- Thank you!
- Contact: [your email]
- Repository: [GitHub link if applicable]

**Speaker notes:** Prepare answers for: "Why simulated AI?", "How accurate?", "PostgreSQL vs Supabase?"

---

## Demo Checklist (Before Defense)
- [ ] PostgreSQL running with `postgresql/schema.sql` applied
- [ ] Backend: `cd backend && python main.py`
- [ ] Farmer app: http://localhost:8081
- [ ] Admin: http://localhost:8080 — login `admin@agrismartai.ph` / `admin123`
- [ ] Sample rice leaf images ready in gallery folder
- [ ] Laptop charged + hotspot backup
