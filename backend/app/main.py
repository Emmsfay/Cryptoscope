from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import httpx
from prometheus_fastapi_instrumentator import Instrumentator

from app.routers import prices, coins
from app.services.coingecko import CoinGeckoService


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(timeout=10.0)
    app.state.coingecko = CoinGeckoService(app.state.http_client)
    yield
    await app.state.http_client.aclose()


app = FastAPI(
    title="CryptoScope API",
    description="Real-time crypto price tracking powered by CoinGecko",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(prices.router, prefix="/api/prices", tags=["prices"])
app.include_router(coins.router, prefix="/api/coins", tags=["coins"])

# Expose /metrics endpoint for Prometheus scraping
Instrumentator().instrument(app).expose(app)


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "cryptoscope-api"}
