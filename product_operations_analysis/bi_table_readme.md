# 数据库表说明文档：bi_warehouse_dw_us_product_daily

## 1. 基本信息
| 项目 | 内容 |
| :--- | :--- |
| **表名** | `bi_warehouse_dw_us_product_daily` |
| **层级** | DW / DWS (汇总层) |
| **主题** | 平台流量与商品转化表现 (美西时间) |
| **存储引擎** | Hybrid (含 SE 索引) |
| **更新频率** | 天 (Daily) |
| **描述** | 基于美西时间（PST）统计的全站/全平台维度漏斗转化与流量指标表。 |

---

## 2. 统计维度 (Dimensions)
> **注意**：以下字段构成了该表的联合主键（PK），共同决定了数据的唯一粒度。

| 字段名 | 类型 | 业务含义 | 备注 / 维护建议 |
| :--- | :--- | :--- | :--- |
| **us_time** | `text` | **日期 (PST)** | 格式通常为 `YYYYMMDD` |
| **site** | `text` | **站点** | 例如：US, UK, DE, FR 等 |
| **platform** | `text` | **平台** | 常用主平台枚举：`iOS`、`Android`、`Web`、`PC`；`iPhone` 仅少量历史/异常残留。表内存在少量明显脏值/攻击字符串，分析时建议优先过滤到上述主平台枚举。 |
| **version** | `text` | **APP版本** | 统计不同版本下的用户行为 |
| **country** | `text` | **国家** | 用户访问所属的国家代码 |
| **language** | `text` | **语言** | 用户当前使用的界面语言 |
| **source** | `text` | **流量来源** | 如：Direct, Google, Facebook, Email 等 |
| **new_return** | `text` | **用户身份** | 新用户 (New) 或 老用户 (Return) |
| **new_return_paid** | `text` | **付费身份(全局)** | 历史上是否有过付费记录的用户标识 |
| **new_return_platform_paid** | `text` | **付费身份(分平台)** | 在当前平台下是否有过付费记录的用户标识 |

---

## 3. 全链路转化漏斗 (Conversion Funnel)
> **大模型友好提示**：各阶段均提供 PV（行为次数）和 UV（独立用户数）两个指标。

| 漏斗阶段 | PV 字段 (次数) | UV 字段 (人数) | 业务逻辑说明 |
| :--- | :--- | :--- | :--- |
| **1. 曝光** | `impression_pv` | `impression_uv` | 商品在列表页、活动页、推荐位被展示 |
| **2. 列表点击** | `list_click_pv` | `list_click_uv` | 用户在列表/分类页点击了具体商品 |
| **3. 详情访问** | `click_pv` | `click_uv` | 用户进入商品详情页 (PDP) 的行为 |
| **4. 心愿单** | `product_favor_pv` | `product_favor_uv` | 用户收藏商品或添加心愿单 |
| **5. 加购** | `add_cart_pv` | `add_cart_uv` | 点击“加入购物车”按钮 |
| **6. 结算启动** | `checkout_pv` | `checkout_uv` | 点击“去结算”进入订单提交流程 |
| **7. 最终购买** | `purchase_pv` | `purchase_uv` | 成功支付，订单状态转为已付款 |

---

## 4. 结算流程拆解 (Checkout Details)
> 用于分析从 Checkout 到 Purchase 之间的细分流失点。

| 字段名 | 类型 | 业务含义 | 业务口径 / 逻辑 |
| :--- | :--- | :--- | :--- |
| **shipping_uv** | `bigint` | **地址页 UV** | 进入结算流程后的第一步：填写地址 |
| **payment_uv** | `bigint` | **支付方式页 UV** | 进入结算流程后的第二步：选择支付方式 |
| **paynow_uv** | `bigint` | **支付点击 UV** | 在收银台点击“Pay Now”的行为（临门一脚） |
| **ios_checkout_pv** | `bigint` | **iOS 专属结算 PV** | 针对 iOS 平台的冗余统计，用于校验 |
| **ios_checkout_uv** | `bigint` | **iOS 专属结算 UV** | 针对 iOS 平台的冗余统计，用于校验 |

---

## 5. 综合流量与财务指标 (Traffic & Finance)
| 字段名 | 类型 | 业务含义 | 计算与逻辑 |
| :--- | :--- | :--- | :--- |
| **session** | `bigint` | **会话总数** | 30分钟无操作即切分的访问会话 |
| **bounce_session** | `bigint` | **跳出会话数** | 仅访问了一页就关闭的会话数 |
| **page_view** | `bigint` | **总浏览量** | 全站 PV 总和 |
| **"user"** | `bigint` | **总活跃人数** | 当天活跃的去重独立用户数 (UV) |
| **register_pv/uv** | `bigint` | **注册转化** | 用户完成注册流程的统计 |
| **total_fee** | `numeric` | **GMV (总金额)** | 订单原始总价值（含优惠券、运费） |
| **should_fee** | `numeric` | **应付金额** | 用户最终实际支出的金额 |

---

## 6. 技术配置 (Technical Specs)
*   **主键索引**: `PRIMARY KEY (platform, version, country, source, new_return, new_return_platform_paid, new_return_paid, site, language, us_time)`
*   **存储格式**: `USING hybrid`
*   **TTL 配置**: `gc_ttl_seconds = 18000`
