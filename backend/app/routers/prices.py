from fastapi import APIRouter, Request, Query
from app.models.coin import CoinPrice

router = APIRouter()


@router.get("/", response_model=list[CoinPrice])
async def get_prices(
    request: Request,
    vs_currency: str = Query("usd", description="Target currency"),
    per_page: int = Query(50, ge=1, le=250, description="Results per page"),
    page: int = Query(1, ge=1, description="Page number"),
    order: str = Query("market_cap_desc", description="Sort order"),
):
    """
    Fetch current market prices for top cryptocurrencies.
    Includes sparkline data for 7-day mini charts.
    """
    svc = request.app.state.coingecko
    return await svc.get_markets(
        vs_currency=vs_currency,
        per_page=per_page,
        page=page,
        order=order,
    )
