# Widgets Studio - 项目状态与session总结

> 更新时间：2026-07-07
> 本次session目标：从 HelloWorld 起步，搭建一个可扩展的 iOS 个人信息仪表盘应用骨架，并准备后续向股票/金融方向演进。

---

## 当前已实现

### iOS App (WidgetsStudio)

- **底部 Tab 导航**：首页、行情、组件、设置、登录
- **首页**：显示北京天气（调用 Open-Meteo）
- **行情页 (MarketView)**：大盘指数 + 自选股列表占位
- **组件页**：列出已支持的桌面小组件
- **设置页**：应用信息
- **登录页**：Apple 登录按钮 + 邮箱/密码登录表单
- **通用网络层 (NetworkService)**：
  - 支持 GET/POST/PUT/DELETE/PATCH
  - 自动注入 Bearer Token
  - 统一错误处理 (APIError)
- **图标**：紫色背景白色 W 的 App Icon

### Widget 扩展 (WidgetsStudioWidget)

- **时钟组件**：每分钟刷新，显示当前时间
- **天气组件**：每 30 分钟刷新，请求 Open-Meteo 北京天气

### 后端 (Backend/)

- **FastAPI 骨架**：已按分层架构组织
  - `app/api/v1/endpoints/`：路由
  - `app/core/`：配置、安全、依赖
  - `app/db/`：数据库（占位）
  - `app/models/`：ORM 模型
  - `app/schemas/`：Pydantic 模型
  - `app/services/`：业务逻辑
  - `app/utils/`：工具函数
  - `tests/`：测试结构
  - `alembic/`：数据库迁移
  - `docker-compose.yml`：MySQL 开发环境
- **接口**：
  - `/api/v1/auth/login/email`
  - `/api/v1/auth/login/apple`
  - `/api/v1/auth/register`
  - `/api/v1/weather/beijing`
  - `/api/v1/stocks/quote/{code}`（需登录）
  - `/api/v1/stocks/watchlist`（需登录）

### 文档

- `README.md`：项目简介、结构、运行方式
- `Docs/PRD.md`：产品方向（小组件 → 用户系统 → 股票金融）
- `Docs/Architecture.md`：整体架构与数据流
- `Backend/README.md`：后端运行与接入说明

---

## 关键决策

1. **SwiftUI + WidgetKit**：原生 iOS 方案，HTML/JS 不能用于 WidgetKit 渲染。
2. **Python + FastAPI 后端**：适合金融数据处理，生态丰富（akshare/tushare）。
3. **通用 NetworkService**：前端统一通过 NetworkService 请求后端，JWT Token 自动注入。
4. **Apple 登录延后**：因 Apple Developer 账号 $100 年费，待 App 成熟后再接入。
5. **项目方向**：从小组件工具逐步演进到股票/个人资产管理 dashboard。

---

## 已知问题 / 注意事项

- **Xcode 缓存**：如打开 Xcode 看到红色缺失文件，需 Cmd+Q 完全退出后重开。
- **后端依赖**：Backend/venv 未提交（gitignored），首次运行需按 README 安装。
- **Apple 登录**：当前为 UI 占位，后端 `app/services/auth_service.py` 中需补充 identity token 验证。
- **行情数据**：`app/services/stock_service.py` 当前为 mock，后续接入 akshare / tushare。
- **数据库**：已预留 SQLAlchemy + Alembic 结构，但尚未完整配置连接。

---

## 下一步建议

### 近期

1. 后端跑通：安装依赖，启动 FastAPI，确认 `/docs` 可访问
2. 前端接后端：把 `APIConfiguration.baseURL` 指向本地后端，替换 mock 天气接口
3. 完善登录：邮箱登录接入后端真实校验

### 中期

4. 股票数据：后端接入 akshare/tushare，前端行情页显示真实数据
5. 自选股：数据库 + 接口 + 前端管理
6. 行情小组件：把股票数据展示到桌面小组件

### 远期

7. Apple 登录 + App Store 上架准备
8. 推送通知（股价提醒）
9. 多设备数据同步

---

## 如何继续开发

### 启动 iOS App

```bash
cd /Users/huangxin/Desktop/TestIos
open WidgetsStudio.xcodeproj
# 选择模拟器，Cmd+R
```

### 启动后端

```bash
cd Backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

访问：http://127.0.0.1:8000/docs

---

## Git 状态

- 已初始化 git 仓库
- 已完成初始 commit (`1091ec8`)
- 尚未配置 remote，需手动添加后 push
