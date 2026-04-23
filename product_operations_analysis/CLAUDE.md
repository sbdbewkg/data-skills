# 项目规则

## 数据查询规范

所有数据库查询必须通过 MCP 服务执行，禁止使用 psycopg2、直连数据库等方式。

- MCP 服务地址 .mcp.json 的 mcp-service
- 执行 SQL 时优先使用 Claude 已接入的原生 MCP 工具；若当前会话未暴露 MCP 工具，则允许使用 `Bash` 调用 `claude mcp` 间接执行查询
- 不要尝试安装或使用任何 Python 数据库驱动，也不要用 Python/脚本手工请求 MCP 协议绕过工具调用
- 所有数据查询请求都必须重新执行 SQL，不能复用上一次查询结果充当最新结果
- 各端数据统计分析统一使用 `bi_warehouse_dw_us_product_daily` 表，除非用户明确指定其他表
- 平台字段兼容大小写与常见写法：如用户说 `ios`，查询时应兼容匹配表内实际值 `iOS`
- 运营位相关分析（Banner、活动页、推荐位、首页运营位等具体位置）统一使用 `bi_warehouse_dw_us_operation_daily` 表，字段说明详见 `bi_operation_table_readme.md`
- `site` 字段实际枚举值均为小写，常用值：`usa`（美国）、`uk`（英国）、`eu`（欧盟）、`au`（澳大利亚）、`de`、`fr`、`es`、`ja` 等；查询前如不确定请先 `SELECT DISTINCT site FROM 表名 LIMIT 20`

## 数据库表用途说明

| 表名 | 适用场景 |
| :--- | :--- |
| `bi_warehouse_dw_us_product_daily` | 各端整体 GMV / Session / CVR 等平台表现分析 |
| `bi_warehouse_dw_us_operation_daily` | 运营位分析（首页 Banner、活动页、推荐位、具体运营位置 CTR/转化漏斗等） |
| `bi_warehouse_dw_us_list_id_daily` | 运营位行为数据（按 list_id 聚合，含 list_type/list_title 维度） |
| `bi_warehouse_dw_spu_platform_daily` | SPU 各端 GMV/订单（按 platform 聚合） |

### bi_warehouse_dw_us_operation_daily 核心字段

- 时间：`us_time`（YYYYMMDD，美西时间）
- 维度：`site` / `platform` / `source` / `operationpage_title` / `operation_type` / `operation_position` / `operation_content` / `activity_id`
- 运营位漏斗：`operation_impression_uv` → `operation_click_uv` → `product_exposure_uv` → `product_click_uv` → `add_cart_uv` → `checkout_uv` → `purchase_uv`
- CTR = `operation_click_uv / operation_impression_uv`
- GMV：`total_fee`

## 图片展示规范

所有来自 `img.shopcider.com` 或 `img1.shopcider.com` 域名的图片链接，展示时必须在 URL 末尾追加 OSS 图片处理参数：

```
?x-oss-process=image/resize,w_300,m_lfit/quality,Q_70/format,webp
```

示例：
```
https://img.shopcider.com/hermes/posting/xxx.jpg?x-oss-process=image/resize,w_300,m_lfit/quality,Q_70/format,webp
```
