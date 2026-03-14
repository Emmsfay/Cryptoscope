from fastapi import APIRouter, Request, Query
from app.models.coin import CoinDetail, MarketChart

router = APIRouter()


@router.get("/search")
async def search_coins(
    request: Request,
    q: str = Query(..., min_length=1, description="Search query"),
):
    """Search for coins by name or symbol."""
    svc = request.app.state.coingecko
    return await svc.search_coins(q)


@router.get("/{coin_id}", response_model=CoinDetail)
async def get_coin_detail(request: Request, coin_id: str):
    """Get detailed info for a single coin."""
    svc = request.app.state.coingecko
    return await svc.get_coin_detail(coin_id)


@router.get("/{coin_id}/chart", response_model=MarketChart)
async def get_coin_chart(
    request: Request,
    coin_id: str,
    vs_currency: str = Query("usd"),
    days: int = Query(7, ge=1, le=365),
):
    """Get OHLC price history for charting."""
    svc = request.app.state.coingecko
    return await svc.get_market_chart(coin_id, vs_currency, days)
