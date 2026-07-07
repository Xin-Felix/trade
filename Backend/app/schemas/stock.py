from pydantic import BaseModel


class StockData(BaseModel):
    code: str
    name: str
    price: float
    change_percent: float
    updated_at: str
