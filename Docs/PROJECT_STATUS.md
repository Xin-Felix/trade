# 盈多多 / Ying+ - 项目状态与开发指南

> 更新时间：2026-07-08

---

## 当前已实现

### iOS App (trade_ios/YingPlus)

- **底部 Tab 导航**：首页、行情、组件、接口测试、设置。
- **全局登录态**：`ContentView` 根据 `AuthService.restoreSession()` 决定展示登录页或主界面。
- **验证码登录**：`LoginView` 邮箱 → 获取验证码 → 输入 6 位验证码 → 自动注册/登录。
- **测试账号登录**：开发环境一键登录，方便快速体验。
- **Token 持久化**：`KeychainService` 安全保存 access token。
- **退出登录**：`SettingsView` 清除 Keychain 和内存 token。
- **首页 (HomeView)**：行情概览，展示大盘指数 + 自选股列表；左滑删除自选股。
- **行情页 (MarketView)**：搜索股票代码/名称/拼音，搜索结果可一键加入自选股。
- **行情详情 (StockDetailView)**：分时/日/周/月/年 K 线图，支持捏合缩放、拖拽平移、长按十字光标；分时默认展示，1分钟自动刷新；展示股票指标。
- **指数详情 (IndexDetailView)**：大盘指数日 K 线图。
- **板块资金流向**：行业/概念板块净流入排行 + 动态趋势折线图。
- **自选股**：本地缓存 + 后端同步（`watchlist` 表），按加入时间排序。
- **接口测试 (APITestView)**：底部 Tab，可测试所有后端接口，参数有默认值直接点击即可。
- **K 线图 (KLineChartView)**：自绘 Canvas，Y 轴标签不与 K 线重叠。

### Widget 扩展 (trade_ios/YingPlusWidget)

- **时钟组件**：每分钟刷新，显示当前时间。
- Widget 扩展已正常嵌入主 App Target。

### 后端 (trade_backend)

> 后端为独立 Git 仓库，位于 `trade_backend/`，Docker 部署。

#### 核心路由

| 前缀 | 说明 |
|------|------|
| `/api/v1/auth` | 认证：邮箱验证码登录、密码登录 |
| `/api/v1/stocks` | 股票业务：行情、K线、自选股、资金流、龙虎榜、THS指数、概念归属 |
| `/api/v1/sync` | 数据同步：后台任务触发增量同步（日K/因子/板块/指数/概念等） |
| `/api/v1/ts` | Tushare 代理：124个接口直接透传 Tushare Pro API |
| `/api/v1/weather` | 天气（保留） |

#### Tushare 代理接口结构（/api/v1/ts）

一个接口一个文件，共 124 个端点，按 10 大分类组织：

```
app/api/v1/endpoints/tushare/
├── __init__.py          # 统一入口 + 完整接口目录索引
├── _base.py             # 公共工具函数
├── daily.py             # 历史日线
├── pro_bar.py           # 复权行情
├── fina_indicator.py    # 财务指标
├── limit_list_d.py      # 涨跌停炸板
├── dc_concept_cons.py   # DC题材成分
├── moneyflow_ths.py     # 个股资金流向(THS)
├── ... (共126个文件)
```

分类：
1. **股票基础/行情** (12个)：stock_basic, trade_cal, daily, pro_bar, weekly, monthly, adj_factor, suspend_d, daily_basic, stk_limit, namechange, stk_premarket
2. **财务数据** (10个)：fina_indicator, income, balancesheet, cashflow, forecast, express, dividend, fina_mainbz, fina_audit, disclosure_date
3. **参考数据** (15个)：top10_holders, top10_floatholders, stk_holdernumber, stk_holdertrade, pledge_stat, pledge_detail, repurchase, share_float, block_trade, new_share, stock_company, stk_managers, stk_rewards, stock_hsgt, stock_st
4. **打板/题材/龙虎榜** (27个)：top_list, top_inst, limit_list_d, limit_step, limit_cpt_list, limit_list_ths, kpl_list, kpl_concept_cons, ths_index, ths_daily, ths_member, ths_hot, dc_index, dc_member, dc_daily, dc_hot, dc_concept, dc_concept_cons, tdx_index, tdx_member, tdx_daily, hm_list, hm_detail, stk_auction, stk_auction_o, stk_auction_c, broker_recommend
5. **资金流向** (8个)：moneyflow, moneyflow_hsgt, moneyflow_cnt_ths, moneyflow_ind_ths, moneyflow_ind_dc, moneyflow_mkt_dc, moneyflow_ths, moneyflow_dc
6. **两融数据** (4个)：margin, margin_detail, margin_secs, slb_len
7. **特色数据** (11个)：cyq_perf, cyq_chips, stk_factor, stk_factor_pro, stk_nineturn, hk_hold, stk_surv, report_rc, stk_alert, stk_shock, ccass_hold
8. **ETF/基金** (11个)：fund_basic, fund_daily, fund_nav, fund_share, fund_portfolio, fund_div, fund_manager, fund_adj, etf_basic, etf_index, etf_share_size
9. **指数** (14个)：index_basic, index_daily, index_weekly, index_monthly, index_weight, index_dailybasic, index_classify, index_member_all, index_global, sw_daily, ci_daily, ci_index_member, daily_info, sz_daily_info
10. **宏观/新闻** (14个)：news, major_news, cctv_news, shibor, shibor_lpr, cn_cpi, cn_ppi, cn_gdp, cn_m, cn_pmi, sf_month, eco_cal, research_report, anns_d

#### 数据库表

| 表名 | 说明 |
|------|------|
| users | 用户 |
| email_codes | 邮箱验证码 |
| watchlist | 自选股（按加入时间排序） |
| stock_basic | 股票基础信息 |
| stock_daily | 日K线 |
| stock_weekly | 周K线 |
| stock_monthly | 月K线 |
| stock_yearly | 年K线 |
| stock_daily_basic | 每日指标（PE/PB等） |
| stock_fina_indicator | 财务指标（季度） |
| sector_moneyflow_industry | 行业板块资金流 |
| sector_moneyflow_concept | 概念板块资金流 |
| stock_moneyflow | 个股资金流 |
| moneyflow_hsgt | 沪深港通资金流 |
| index_basic | 指数基础信息 |
| index_daily | 指数日线 |
| stock_limit | 涨跌停 |
| top_list | 龙虎榜明细 |
| top_inst | 龙虎榜机构 |
| ths_index | 同花顺指数 |
| ths_daily | 同花顺指数日线 |
| ths_member | 同花顺指数成分 |
| stock_concept | 股票概念/题材映射（concept_id + ts_code） |

#### 数据同步端点（/api/v1/sync）

| 端点 | 说明 |
|------|------|
| POST /sync/recent | 全量增量同步（日K+因子+板块+指数+涨跌停） |
| POST /sync/daily-kline | 仅日K线 |
| POST /sync/daily-basic | 仅日线因子 |
| POST /sync/sector-moneyflow | 板块资金流 |
| POST /sync/stock-moneyflow | 个股资金流 |
| POST /sync/index-daily | 指数日线 |
| POST /sync/hsgt | 沪深港通 |
| POST /sync/stock-limit | 涨跌停 |
| POST /sync/concept | 概念板块成分映射（全量，耗时几分钟） |

所有同步接口使用 FastAPI BackgroundTasks，调用后立即返回。

---

## 关键决策

1. **SwiftUI + WidgetKit**：原生 iOS 方案。
2. **Python + FastAPI 后端**：适合金融数据处理。
3. **Tushare Pro（付费10000积分）**：主要数据源，akshare 仅用于实时分时。
4. **一接口一文件**：Tushare 代理接口每个独立文件，方便维护查找。
5. **后端不做定时任务**：通过 API 手动/后台管理面板触发同步，后续会接 Vue 管理后台。
6. **Docker 部署**：PostgreSQL + Redis + backend 一键启动。

---

## 已知问题 / 注意事项

- **后端 `.env` 包含敏感信息**：已加入 `.gitignore`。
- **Tushare Token**：需配置 `TUSHARE_TOKEN` 环境变量。
- **Tushare 限流**：10000积分约 200次/分钟，概念同步有 sleep(0.35)。
- **旧 concept API 已弃用**：使用 `ths_index(type=N)` + `ths_member` 替代。
- **后端地址**：开发环境 `http://192.168.31.86:8000`，模拟器 `http://127.0.0.1:8000`。

---

## 下一步

### 近期

1. **Vue 后台管理面板**：管理数据同步任务、查看同步状态、手动触发。
2. **持仓盈亏**：用户录入持仓，展示实时盈亏。
3. **买入卖出策略逻辑**：基于题材、资金流、技术面等数据组合判断。

### 中期

4. 行情提醒小组件。
5. 推送通知（股价/涨跌幅提醒）。

### 远期

6. Apple 登录 + App Store 上架。

---

## 如何继续开发

### 启动后端

```bash
cd /Users/huangxin/Desktop/trade/trade_backend
docker compose up -d --build backend
# 访问 http://192.168.31.86:8000/docs 查看 Swagger 文档
```

### 启动 iOS App

```bash
cd /Users/huangxin/Desktop/trade/trade_ios
open YingPlus.xcodeproj
# 选择模拟器，Cmd+R
```

### 同步数据

```bash
# 通过 iOS 接口测试 Tab 或直接 curl
curl -X POST http://192.168.31.86:8000/api/v1/sync/recent?days=3 -H "Authorization: Bearer YOUR_TOKEN"
curl -X POST http://192.168.31.86:8000/api/v1/sync/concept -H "Authorization: Bearer YOUR_TOKEN"
```
