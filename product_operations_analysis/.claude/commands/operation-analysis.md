# 运营位分析

运营位（Banner、活动页、推荐位、首页运营位等）相关分析统一使用 `bi_warehouse_dw_us_operation_daily` 表。

## 标准口径

- 数据表：`bi_warehouse_dw_us_operation_daily`
- 时间字段：`us_time`（格式 `YYYYMMDD`）
- 常用维度：`site` / `platform` / `operationpage_title` / `operation_type` / `operation_position` / `operation_content` / `activity_id`
- CTR：`SUM(operation_click_uv) / NULLIF(SUM(operation_impression_uv), 0)`
- GMV：`SUM(total_fee)`

## 漏斗口径

```
运营位曝光(operation_impression_uv)
  → 运营位点击(operation_click_uv)     CTR
  → 商品曝光(product_exposure_uv)
  → 商品点击/PDP(product_click_uv)
  → 加购(add_cart_uv)
  → 结算(checkout_uv)
  → 购买(purchase_uv)
```

## 常用查询模板

### CTR 分析（按运营位类型）

```sql
SELECT
  operation_type,
  operation_position,
  SUM(operation_impression_uv) AS impression_uv,
  SUM(operation_click_uv) AS click_uv,
  ROUND(SUM(operation_click_uv)::numeric / NULLIF(SUM(operation_impression_uv), 0) * 100, 2) AS ctr_pct,
  ROUND(SUM(total_fee)::numeric, 2) AS gmv
FROM bi_warehouse_dw_us_operation_daily
WHERE us_time BETWEEN '{start_date}' AND '{end_date}'
  AND site = '{site}'
GROUP BY operation_type, operation_position
ORDER BY impression_uv DESC NULLS LAST;
```

### 完整漏斗分析（按运营页面）

```sql
SELECT
  operationpage_title,
  SUM(operation_impression_uv) AS impression_uv,
  SUM(operation_click_uv) AS click_uv,
  ROUND(SUM(operation_click_uv)::numeric / NULLIF(SUM(operation_impression_uv), 0) * 100, 2) AS ctr_pct,
  SUM(product_exposure_uv) AS product_exposure_uv,
  SUM(product_click_uv) AS product_click_uv,
  SUM(add_cart_uv) AS add_cart_uv,
  SUM(checkout_uv) AS checkout_uv,
  SUM(purchase_uv) AS purchase_uv,
  ROUND(SUM(total_fee)::numeric, 2) AS gmv
FROM bi_warehouse_dw_us_operation_daily
WHERE us_time BETWEEN '{start_date}' AND '{end_date}'
  AND site = '{site}'
GROUP BY operationpage_title
ORDER BY gmv DESC NULLS LAST;
```

### 活动专项分析

```sql
SELECT
  activity_id,
  operation_content,
  SUM(operation_impression_uv) AS impression_uv,
  SUM(operation_click_uv) AS click_uv,
  ROUND(SUM(operation_click_uv)::numeric / NULLIF(SUM(operation_impression_uv), 0) * 100, 2) AS ctr_pct,
  SUM(purchase_uv) AS purchase_uv,
  ROUND(SUM(total_fee)::numeric, 2) AS gmv
FROM bi_warehouse_dw_us_operation_daily
WHERE us_time BETWEEN '{start_date}' AND '{end_date}'
  AND activity_id = {activity_id}
GROUP BY activity_id, operation_content
ORDER BY gmv DESC NULLS LAST;
```

## 输出要求

1. **口径说明**：时间范围、site、筛选条件
2. **漏斗数据**：各环节 UV 及逐级转化率
3. **CTR 表现**：与行业/历史均值对比
4. **GMV 贡献**：各运营位 GMV 占比
5. **核心结论**：高流量低转化 / 高 CTR 但 GMV 弱 / 漏斗断层位置

## 注意事项

- `operation_image` 字段若为图片 URL（`img.shopcider.com` / `img1.shopcider.com`），展示时必须追加 `?x-oss-process=image/resize,w_300,m_lfit/quality,Q_70/format,webp`
- `site` 枚举为小写，如 `usa`、`uk`、`eu`、`au`
- 维度过多时会导致行数膨胀，建议先按核心维度汇总，再按需下钻
