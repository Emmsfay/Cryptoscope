# CryptoScope

Real-time cryptocurrency price tracker — built as a full DevOps learning project.

**Stack:** Python FastAPI · React + TypeScript · CoinGecko API  
**Deployment:** AWS EKS · Terraform · GitHub Actions · Prometheus + Grafana

---

## Project Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | App (FastAPI + React) | ✅ |
| 2 | Containerise (Docker + ECR) | ⬜ |
| 3 | Infrastructure (Terraform + EKS) | ⬜ |
| 4 | Deploy to EKS (K8s manifests) | ⬜ |
| 5 | CI/CD (GitHub Actions) | ⬜ |
| 6 | Observability (Prometheus + Grafana) | ⬜ |

---

## Phase 1 — Running Locally

### Prerequisites
- Python 3.12+
- Node 20+
- (Optional) Docker + Docker Compose

### Option A — Docker Compose (recommended)

```bash
docker compose up --build
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:8000
- API docs: http://localhost:8000/docs

### Option B — Run services manually

**Backend:**
```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/prices/` | Top N coins with sparklines |
| GET | `/api/coins/search?q=bitcoin` | Search coins |
| GET | `/api/coins/{id}` | Coin detail |
| GET | `/api/coins/{id}/chart?days=7` | Price history |
| GET | `/health` | Health check |

Interactive docs available at `/docs` (Swagger UI) and `/redoc`.

---

## Project Structure

```
cryptoscope/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI app + lifespan
│   │   ├── routers/
│   │   │   ├── prices.py    # /api/prices
│   │   │   └── coins.py     # /api/coins
│   │   ├── services/
│   │   │   └── coingecko.py # CoinGecko API client
│   │   └── models/
│   │       └── coin.py      # Pydantic schemas
│   ├── requirements.txt
│   └── Dockerfile.dev
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Sparkline.tsx
│   │   │   ├── PriceChange.tsx
│   │   │   └── CoinChart.tsx
│   │   ├── hooks/
│   │   │   ├── usePrices.ts  # Auto-polling every 30s
│   │   │   └── useCoinChart.ts
│   │   ├── services/
│   │   │   └── api.ts        # Axios client
│   │   └── pages/
│   │       └── Dashboard.tsx
│   └── Dockerfile.dev
└── docker-compose.yml
```

---

## CoinGecko API

The free tier (no API key) allows ~10–30 calls/minute. For higher limits:

1. Register at https://www.coingecko.com/en/api
2. Add your key to `backend/.env`:
   ```
   COINGECKO_API_KEY=your_key_here
   ```

---

## Next: Phase 2 — Containerise for Production

Phase 2 adds multi-stage production Dockerfiles and pushes images to AWS ECR.
