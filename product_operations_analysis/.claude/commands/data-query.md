# 数据查询统一规范

所有数据问题都必须通过 `mcp__mcp-service__executeQuery` 重新执行 SQL 获取最新结果，禁止复用历史查询结果、禁止使用 psycopg2 / psql / 直连字符串等绕过 MCP 的方式。

## 执行原则

- 每次回答数据问题前，先根据用户问题重新编写并执行 SQL
- 统一通过 `mcp__mcp-service__executeQuery` 执行查询
- 若用户未明确指定数据表，按场景自动选表：
  - 平台整体表现、GMV、Session、CVR、趋势分析：`bi_warehouse_dw_us_product_daily`
  - 运营位、Banner、活动页、推荐位、首页运营位、漏斗、CTR 分析：`bi_warehouse_dw_us_operation_daily`
  - list_id / list_type / list_title 相关运营位行为分析：`bi_warehouse_dw_us_list_id_daily`
  - SPU 各端 GMV / 订单分析：`bi_warehouse_dw_spu_platform_daily`
- 若查询结果为空，不直接下结论，先排查：
  - 时间范围是否合理
  - `site` 枚举值是否写对
  - 指标字段与维度口径是否匹配
- 若输出中包含 `img.shopcider.com` 或 `img1.shopcider.com` 图片链接，必须在 URL 末尾追加：
  `?x-oss-process=image/resize,w_300,m_lfit/quality,Q_70/format,webp`

## 常用口径

### 平台表现

- 表：`bi_warehouse_dw_us_product_daily`
- 时间字段：`us_time`
- 常用维度：`site`、`platform`
- GMV：`SUM(total_fee)`
- Session：`SUM(session)`
- CVR：`SUM(purchase_uv) / NULLIF(SUM("user"), 0)`

### 运营位分析

- 表：`bi_warehouse_dw_us_operation_daily`
- 常用维度：`site` / `platform` / `source` / `operationpage_title` / `operation_type` / `operation_position` / `operation_content` / `activity_id`
- 漏斗：`operation_impression_uv` → `operation_click_uv` → `product_exposure_uv` → `product_click_uv` → `add_cart_uv` → `checkout_uv` → `purchase_uv`
- CTR：`SUM(operation_click_uv) / NULLIF(SUM(operation_impression_uv), 0)`
- GMV：`SUM(total_fee)`

### list_id 行为分析

- 表：`bi_warehouse_dw_us_list_id_daily`
- 常用维度：`platform`、`country`、`source`、`list_type`、`list_title`
- 已知口径：`list_type = 1` 对应首页运营位；`source = '自然流量'` 可用于自然流量筛选

### SPU 各端分析

- 表：`bi_warehouse_dw_spu_platform_daily`
- 常用维度：`spu`、`platform`
- 常用指标：GMV、订单量

## 输出要求

回答时至少包含：

1. 口径说明：使用的数据表、时间范围、核心指标定义
2. 关键结果：用简洁表格或分点给出核心数据
3. 核心结论：明确指出变化、异常、贡献来源或优化方向

如用户问题不完整，先补齐必要筛选条件；若无需追问，则按默认业务口径执行 SQL 并说明默认条件。
