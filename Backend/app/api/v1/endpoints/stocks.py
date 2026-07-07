from fastapi import APIRouter, Depends

from app.core.dependencies import get_current_user
from app.schemas.stock import StockData
from app.schemas.user import User
from app.services import stock_service

router = APIRouter()


@router.get("/quote/{code}")
async def get_stock_quote(code: str, user: User = Depends(get_current_user)) -> StockData:
    return stock_service.get_stock_quote(code)


@router.get("/watchlist")
async def get_watchlist(user: User = Depends(get_current_user)) -> list[StockData]:
    return stock_service.get_user_watchlist()
