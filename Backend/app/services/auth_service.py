from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash, verify_password
from app.models.user import User as UserModel
from app.schemas.token import TokenResponse
from app.schemas.user import User


def authenticate_email(db: Session, email: str, password: str) -> TokenResponse:
    """邮箱登录：校验 bcrypt 哈希密码并返回 JWT。"""
    user = db.query(UserModel).filter(UserModel.email == email).first()
    if user is None or not verify_password(password, user.hashed_password):
        raise ValueError("邮箱或密码错误")

    token = create_access_token({"sub": user.public_id, "email": user.email})
    return TokenResponse(
        access_token=token,
        user=User(id=user.public_id, email=user.email, name=user.name),
    )


def create_user(db: Session, email: str, password: str, name: str | None = None) -> UserModel:
    """创建用户（注册用），密码使用 bcrypt 哈希。"""
    if db.query(UserModel).filter(UserModel.email == email).first():
        raise ValueError("邮箱已存在")

    user = UserModel(
        email=email,
        hashed_password=get_password_hash(password),
        name=name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_apple(identity_token: str, user_id: str) -> TokenResponse:
    """
    Apple 登录（占位）。
    真实流程：
    1. 用 Apple 公钥验证 identity_token
    2. 根据 sub（user_id）查找或创建用户
    3. 返回自己的 JWT
    """
    # TODO: 验证 Apple identity token
    user = User(id=user_id, email="apple_user@example.com", name="Apple User")
    token = create_access_token({"sub": user.id, "email": user.email})
    return TokenResponse(access_token=token, user=user)
