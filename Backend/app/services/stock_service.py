from datetime import datetime

from app.schemas.stock import StockData


def get_stock_quote(code: str) -> StockData:
    """
    获取单只股票行情（占位）。
    后面接 akshare / tushare 等库获取真实数据。
    """
    return StockData(
        code=code,
        name=f"股票 {code}",
        price=10.0,
        change_percent=1.23,
        updated_at=datetime.now().isoformat(),
    )


def get_user_watchlist() -> list[StockData]:
    """获取用户自选股（占位）。"""
    return [
        StockData(
            code="000001",
            name="平安银行",
            price=12.5,
            change_percent=2.1,
            updated_at=datetime.now().isoformat(),
        ),
        StockData(
            code="000002",
            name="万科A",
            price=15.3,
            change_percent=-0.8,
            updated_at=datetime.now().isoformat(),
        ),
    ]
