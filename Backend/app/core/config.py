from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")

    app_name: str = "Widgets Studio Backend"
    # 生产环境必须改成随机字符串（至少 32 字节），并通过环境变量注入
    secret_key: str = "your-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 天
    apple_client_id: str = ""  # Apple Sign In 的 Bundle ID

    # MySQL 数据库连接
    database_url: str = "mysql+pymysql://widgets_user:widgets_password@127.0.0.1:3306/widgets_studio"


settings = Settings()
