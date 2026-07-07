# Widgets Studio 后端

基于 FastAPI 的分层后端服务骨架。

## 目录结构

```
Backend/
├── alembic/                  # 数据库迁移（后续接入）
├── app/
│   ├── main.py               # FastAPI 应用入口
│   ├── api/
│   │   └── v1/
│   │       ├── api.py        # v1 路由聚合
│   │       └── endpoints/    # 各模块路由
│   │           ├── auth.py
│   │           ├── weather.py
│   │           └── stocks.py
│   ├── core/                 # 核心配置、安全、依赖
│   │   ├── config.py
│   │   ├── security.py
│   │   └── dependencies.py
│   ├── db/                   # 数据库相关（后续接入）
│   ├── models/               # ORM 模型（后续接入）
│   ├── schemas/              # Pydantic 请求/响应模型
│   ├── services/             # 业务逻辑层
│   └── utils/                # 通用工具
├── tests/                    # 测试
├── main.py                   # 兼容入口，转发自 app/main.py
├── requirements.txt
└── README.md
```

## 运行

```bash
cd Backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

访问：http://127.0.0.1:8000/docs

## 接口

基础接口：

- `GET /`：服务状态
- `GET /health`：健康检查

v1 接口（前缀 `/api/v1`）：

- `POST /api/v1/auth/login/email`：邮箱登录（占位：test@example.com / 123456）
- `POST /api/v1/auth/login/apple`：Apple 登录（占位）
- `POST /api/v1/auth/register`：邮箱注册（占位）
- `GET /api/v1/weather/beijing`：北京天气
- `GET /api/v1/stocks/quote/{code}`：股票行情（需登录，占位）
- `GET /api/v1/stocks/watchlist`：自选股（需登录，占位）

## 环境变量

复制 `.env.example` 为 `.env` 并修改：

```bash
cp .env.example .env
```

## 后续接入

1. **登录授权**：`app/core/dependencies.py` 已写好 JWT 校验占位，替换为用户数据库查询。
2. **Apple 登录**：在 `app/services/auth_service.py` 的 `authenticate_apple` 里验证 identity_token。
3. **股票数据**：在 `app/services/stock_service.py` 里接入 akshare / tushare。
4. **数据库**：建议用 PostgreSQL + SQLAlchemy，先解注释 `app/db/base.py` 和 `app/models/user.py`。
5. **迁移**：配置 alembic，替换 `alembic/` 占位文件。
6. **测试**：在 `tests/` 下继续补充单元测试和接口测试。
