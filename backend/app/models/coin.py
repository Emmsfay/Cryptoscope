from pydantic import BaseModel
from typing import Optional


class SparklineData(BaseModel):
    price: list[float] = []


class CoinPrice(BaseModel):
    id: str
    symbol: str
    name: str
    image: str
    current_price: Optional[float] = None
    market_cap: Optional[float] = None
    market_cap_rank: Optional[int] = None
    total_volume: Optional[float] = None
    price_change_percentage_1h_in_currency: Optional[float] = None
    price_change_percentage_24h_in_currency: Optional[float] = None
    price_change_percentage_7d_in_currency: Optional[float] = None
    price_change_percentage_24h: Optional[float] = None
    circulating_supply: Optional[float] = None
    sparkline_in_7d: Optional[SparklineData] = None

    class Config:
        extra = "ignore"


class CoinDetail(BaseModel):
    id: str
    symbol: str
    name: str
    image: str
    description: str
    market_data: dict

    class Config:
        extra = "ignore"


class MarketChart(BaseModel):
    prices: list[list[float]]
    market_caps: list[list[float]]
    total_volumes: list[list[float]]


class MarketsQuery(BaseModel):
    vs_currency: str = "usd"
    per_page: int = 50
    page: int = 1
    order: str = "market_cap_desc"
