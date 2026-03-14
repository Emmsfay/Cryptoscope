import httpx
from typing import Optional
from app.models.coin import CoinPrice, CoinDetail, MarketChart


COINGECKO_BASE = "https://api.coingecko.com/api/v3"


class CoinGeckoService:
    def __init__(self, client: httpx.AsyncClient):
        self.client = client

    async def get_markets(
        self,
        vs_currency: str = "usd",
        per_page: int = 50,
        page: int = 1,
        order: str = "market_cap_desc",
    ) -> list[CoinPrice]:
        resp = await self.client.get(
            f"{COINGECKO_BASE}/coins/markets",
            params={
                "vs_currency": vs_currency,
                "order": order,
                "per_page": per_page,
                "page": page,
                "sparkline": True,
                "price_change_percentage": "1h,24h,7d",
            },
        )
        resp.raise_for_status()
        return [CoinPrice(**c) for c in resp.json()]

    async def get_coin_detail(self, coin_id: str) -> CoinDetail:
        resp = await self.client.get(
            f"{COINGECKO_BASE}/coins/{coin_id}",
            params={
                "localization": False,
                "tickers": False,
                "market_data": True,
                "community_data": False,
                "developer_data": False,
            },
        )
        resp.raise_for_status()
        data = resp.json()
        return CoinDetail(
            id=data["id"],
            symbol=data["symbol"],
            name=data["name"],
            image=data["image"]["large"],
            description=data["description"].get("en", ""),
            market_data=data["market_data"],
        )

    async def get_market_chart(
        self,
        coin_id: str,
        vs_currency: str = "usd",
        days: int = 7,
    ) -> MarketChart:
        resp = await self.client.get(
            f"{COINGECKO_BASE}/coins/{coin_id}/market_chart",
            params={"vs_currency": vs_currency, "days": days},
        )
        resp.raise_for_status()
        data = resp.json()
        return MarketChart(
            prices=data["prices"],
            market_caps=data["market_caps"],
            total_volumes=data["total_volumes"],
        )

    async def search_coins(self, query: str) -> list[dict]:
        resp = await self.client.get(
            f"{COINGECKO_BASE}/search",
            params={"query": query},
        )
        resp.raise_for_status()
        return resp.json().get("coins", [])[:10]
