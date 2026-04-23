# 各端周度数据分析

查询最近一周各端（platform）GMV、Session、CVR 表现时，统一使用 `bi_warehouse_dw_us_product_daily` 表。

## 标准口径

- 数据表：`bi_warehouse_dw_us_product_daily`
- 时间字段：`us_time`（格式 `YYYYMMDD`）
- 平台维度：`platform`
- GMV：`SUM(total_fee)`
- Session：`SUM(session)`
- CVR：`SUM(purchase_uv) / NULLIF(SUM("user"), 0)`
- 默认范围：最近一周

## 查询模板

用户未指定时间时，默认查询最近一周：

```sql
SELECT
  platform,
  ROUND(SUM(total_fee)::numeric, 2) AS gmv,
  SUM(session) AS session,
  ROUND(SUM(purchase_uv)::numeric / NULLIF(SUM("user"), 0) * 100, 2) AS cvr_pct
FROM bi_warehouse_dw_us_product_daily
WHERE us_time BETWEEN '{start_date}' AND '{end_date}'
GROUP BY platform
ORDER BY gmv DESC NULLS LAST;
```

其中：
- `{start_date}` / `{end_date}` 使用 `YYYYMMDD` 格式
- 若用户要求按天趋势，则按 `us_time, platform` 分组
- 若用户要求分析某个站点，增加 `site = 'xxx'` 条件

## 国家目标信息（3月）

| 国家 | 目标 Session | 目标 GMV | 目标 CVR |
|---|---:|---:|---:|
| US | 10,936,273 | 8,413,874 | 1.06% |
| GB | 3,957,004 | 3,414,008 | 1.27% |
| EU | 11,204,080 | 7,076,192 | 0.74% |
| AU | 807,988 | 545,588 | 0.98% |

## 输出要求

输出各端：
- GMV
- Session
- CVR
- 排名
- 核心结论（谁贡献最高、谁转化最好、谁流量高但转化偏弱）

同时输出各国家：
- 目标 Session / 实际 Session / Session 完成率
- 目标 GMV / 实际 GMV / GMV 完成率
- 目标 CVR / 实际 CVR / CVR 达成情况
- 当前时间进度（已过天数 / 当月总天数）

时间进度口径：
- 按当月自然日计算
- 输出格式示例：`17/31 = 54.84%`

如用户未特别说明，优先按该口径回答各端表现问题，并附带各国家目标完成情况与时间进度。
