# 数据库表说明文档：bi_warehouse_dw_us_operation_daily

## 1. 基本信息
| 项目 | 内容 |
| :--- | :--- |
| **表名** | `bi_warehouse_dw_us_operation_daily` |
| **层级** | DW / DWS (汇总层) |
| **主题** | 运营位曝光点击与商品转化表现 (美西时间) |
| **更新频率** | 天 (Daily) |
| **描述** | 基于美西时间（PST）统计的全站运营位（Banner、活动页、推荐位等）流量与转化指标表，可按运营页面、运营类型、运营位置等维度下钻分析。 |

---

## 2. 统计维度 (Dimensions)
> **注意**：以下字段共同构成数据的唯一粒度，查询时需注意维度组合导致的数据膨胀。

| 字段名 | 类型 | 业务含义 | 备注 |
| :--- | :--- | :--- | :--- |
| **us_time** | `text` | **日期 (PST)** | 格式通常为 `YYYYMMDD` |
| **site** | `text` | **站点** | 如：usa, uk, de, fr 等 |
| **platform** | `text` | **平台** | 如：PC, Web, Android, iOS |
| **country** | `text` | **国家** | 用户访问所属的国家代码 |
| **language** | `text` | **语言** | 用户当前使用的界面语言 |
| **source** | `text` | **流量来源** | 如：自然流量, push, facebook 等，口径与 product_daily 一致 |
| **operationpage_title** | `text` | **运营页面名称** | 运营位所在页面的标题，如首页、活动页等 |
| **operation_type** | `text` | **运营位类型** | 如：Banner、弹窗、推荐位、限时活动等 |
| **operation_content** | `text` | **运营内容标识** | 该运营位承载的具体内容描述或 ID |
| **operation_position** | `text` | **运营位置** | 运营位在页面中的位置标识，如 top/mid/bottom 或坑位编号 |
| **link_url** | `text` | **跳转链接** | 点击运营位后的目标 URL |
| **url** | `text` | **页面 URL** | 运营位所在页面的 URL |
| **activity_id** | `bigint` | **活动 ID** | 关联的运营活动唯一标识 |
| **operation_tag** | `text` | **运营标签** | 运营位的分类标签，用于多维归组 |
| **operation_image** | `text` | **运营图片** | 运营位使用的素材图片标识或 URL |
| **new_return_visit** | `text` | **访问身份** | 新访客 (New) 或 回访用户 (Return) |
| **new_return_buy_no_platform** | `text` | **付费身份(全局)** | 历史上是否有过付费记录（跨平台） |
| **new_return_buy_platform** | `text` | **付费身份(分平台)** | 在当前平台下是否有过付费记录 |
| **pt** | `text` | **分区字段** | 数据分区标识，通常用于存储优化 |

---

## 3. 运营位转化漏斗 (Operation Funnel)
> **大模型友好提示**：漏斗分两层——①运营位本身的曝光点击，②运营位带出的商品曝光与转化。

### 3.1 运营位层（Operation Level）
| 漏斗阶段 | PV 字段 | UV 字段 | 业务逻辑说明 |
| :--- | :--- | :--- | :--- |
| **1. 运营位曝光** | `operation_impression_pv` | `operation_impression_uv` | 运营位（Banner/弹窗/推荐位）被用户看到 |
| **2. 运营位点击** | `operation_click_pv` | `operation_click_uv` | 用户点击了运营位，进入目标页面 |

> 运营位点击率 CTR = `operation_click_uv / operation_impression_uv`

### 3.2 商品层（Product Level）
| 漏斗阶段 | PV 字段 | UV 字段 | 业务逻辑说明 |
| :--- | :--- | :--- | :--- |
| **3. 商品曝光** | `product_exposure` | `product_exposure_uv` | 点击运营位后，商品在列表/落地页被展示 |
| **4. 商品点击(PDP)** | `product_click` | `product_click_uv` | 用户进入运营位带出的商品详情页 |
| **5. 加购** | `add_cart_pv` | `add_cart_uv` | 用户将商品加入购物车 |
| **6. 收藏** | `product_favor_pv` | `product_favor_uv` | 用户收藏商品或添加心愿单 |
| **7. 结算启动** | `checkout_pv` | `checkout_uv` | 点击"去结算"进入订单提交流程 |
| **8. 最终购买** | `purchase_pv` | `purchase_uv` | 成功支付，订单状态转为已付款 |

---

## 4. 结算补充字段 (Checkout Details)
| 字段名 | 类型 | 业务含义 | 备注 |
| :--- | :--- | :--- | :--- |
| **ios_checkout_pv** | `bigint` | **iOS 专属结算 PV** | iOS 平台的结算次数，可与 checkout_pv 交叉校验 |
| **ios_checkout_uv** | `bigint` | **iOS 专属结算 UV** | iOS 平台的结算人数，可与 checkout_uv 交叉校验 |

---

## 5. 综合流量与财务指标 (Traffic & Finance)
| 字段名 | 类型 | 业务含义 | 计算与逻辑 |
| :--- | :--- | :--- | :--- |
| **session** | `bigint` | **会话总数** | 30分钟无操作即切分的访问会话数 |
| **"user"** | `bigint` | **活跃用户数** | 当天去重独立访客数 (UV) |
| **sale_num** | `bigint` | **销售件数** | 成功支付的商品总件数（非订单数） |
| **total_fee** | `numeric` | **GMV（总金额）** | 订单原始总价值（含优惠券、运费） |

---

## 6. 常用分析场景

| 分析目标 | 推荐用法 |
| :--- | :--- |
| **运营位 CTR 分析** | `GROUP BY operation_type, operation_position`，计算 `operation_click_uv / operation_impression_uv` |
| **运营位 GMV 贡献** | `GROUP BY operationpage_title, operation_content`，汇总 `total_fee` |
| **运营位完整漏斗** | 曝光 → 点击 → 商品曝光 → PDP → 加购 → 结算 → 购买 逐级计算转化率 |
| **新老用户运营效果对比** | `GROUP BY new_return_visit` 或 `new_return_buy_platform` |
| **分渠道运营效果** | `source` 字段口径与 `bi_warehouse_dw_us_product_daily` 一致，可复用渠道归类 CASE WHEN |
| **活动专项分析** | `WHERE activity_id = ?` 过滤特定活动 |
