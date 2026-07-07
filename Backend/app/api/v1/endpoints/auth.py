from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.schemas.auth import EmailLoginRequest
from app.schemas.token import TokenResponse
from app.services import auth_service

router = APIRouter()


@router.post("/login/email", response_model=TokenResponse)
async def login_email(
    payload: EmailLoginRequest,
    db: Session = Depends(get_db),
):
    try:
        return auth_service.authenticate_email(db, payload.email, payload.password)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)
        ) from exc


@router.post("/login/apple", response_model=TokenResponse)
async def login_apple(identity_token: str, user_id: str):
    return auth_service.authenticate_apple(identity_token, user_id)

# 注册接口后续补充，暂时不暴露
# @router.post("/register")
# async def register(...)
