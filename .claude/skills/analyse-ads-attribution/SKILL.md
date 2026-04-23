# Skill: Analyze Ads Attribution (LT 24H vs FT 28D)

## 概述 (Overview)
本技能用于在 `cider_data_warehouse` 中执行广告归因深度分析，核心对比 **Last-Touch (LT) 24H ROI** 与 **First-Touch (FT) 28D ROI**。它旨在识别广告的即时收割价值与长效获客/种草价值。

## 执行准则 (Execution Guidelines)
1. **默认二次透视分析**: 默认情况下，分析应采用“两级下钻”视角：
   - 第一级: **广告目标 (Objective)** (如 `conver`, `daba`, `app`)。
   - 第二级: **广告形式 (Ad Format)** (基于 `ad_name` 区分 `Video`, `Picture`, `Unknown`)。
2. **指标完整性**: 分析必须同时包含 **ROI** 和 **CAC** 指标 (LT 24H 和 FT 28D)。
3. **主动澄清**: 如果用户表达的分析意图不清晰，必须在使用本技能前向用户 **Clarify**:
   - **地域范围**: 是全局分析还是特定国家 (如 US)？
   - **时间窗口**: 需要看 7 天还是 28 天的 FT 归因？
   - **对比基准**: 是否需要对比特定的投手或 Campaign？

## 核心指标定义 (Core Metrics Definitions)

⚠️ **GMV、订单数、CAC 的计算逻辑以 `.claude/skills/analyse-ads-data/SKILL.md` 为准。**

**简要说明：**
- **LT GMV/ROI**: 必须累加 Web/App 新老客四端 GMV (`web_new_total_fee + web_old_total_fee + app_new_gmv + app_old_gmv`)，严禁直接使用 `total_fee24`。
- **LT 订单数**: 累加四端订单数 (`web_new_purchase_orders + web_old_purchase_orders + app_new_purchase_orders + app_old_purchase_orders`)。
- **FT GMV/ROI**: 使用 `dws_user_journey_simplification_long` 表的 `total_fee`，按 `window_period` 筛选。
- **FT 订单数**: 对 `order_id` 去重计数。
- **CAC 计算**: `Spend / New_Orders`（LT 用四端新客订单数，FT 用 `order_new_old_type = '新客'` 筛选）。

详细的字段映射、EROI/ECAC 加权逻辑、SQL 模板请参考 `analyse-ads-data/SKILL.md`。

## 素材分类修正规则 (Creative Mapping Rules)
1. **AIGC = Video**: 在 `objective = 'conver'` 的广告中，`ad_name` 包含 `aigc` 的一律认定为 **视频类型 (Video)**。
2. **素材识别优先级**: 必须下钻到 **Ad Level** 扫描 `ad_name` 进行识别，Campaign Level 的命名（如 `MixSC`）会导致大量数据丢失。
3. **Unknown 分类**: 包含 `Dynamic Creative (DCO)` 或 `Advantage+ Catalog Ads`，在 `conver` 下常通过 `ALL_PRODUCTS` 或系统编号辨认。

## 技术坑点与解决方案 (Technical Pitfalls & Solutions)
- **时间对齐 (Time Alignment)**: 
  - **坑**: 直接关联 `report_date` 和 `order_time` 会导致 ROI 错位。
  - **解**: 必须将消耗表的 `report_date` 关联订单表的 **`time_period_first_touch_event_time`** (用户首次点击时间)。
- **Link_ID 的空字符串 (Empty String Trap)**:
  - **现状**: FT 表中的 `link_id` 存在约 **58% 的空字符串 (`''`)**。
  - **解**: 关联分析后需根据 Link_ID 填充率进行 **向上校准 (Estimated ROI)**，以还原真实获客能力。
- **数据冗余 (Window Redundancy)**:
  - **现象**: 同一订单在 7D 和 28D 下的 FT 归因结果往往一致。
  - **逻辑**: 该表锁定的通常是那笔订单背后的“全局第一个触点”。

## 业务决策建议 (Strategic Insights)
- **视频 (Video/AIGC)**: 是美国市场的拉新引擎。FT-28D 增益通常是 LT-24H 的 **1.7x - 7x**。千万不能只按 24H ROI 考核视频，否则会杀掉所有的种草利器。
- **图片 (Picture)**: 是高效率的收割工具。即时 ROI (LT-24H) 高，但几乎没有长尾效应。
- **DABA**: 兼顾即时收割与长效获客，是目前最稳健的 ROI 支撑。

## 术语 (Jargon)
- **PA （Partnership Ads)** 特指直接利用Influencer/kol账号投放的广告，多为视频广告，广告名称中通常含有-partner-、-pa- 或者实战中常见的简写 **-partn-**

## 常用 SQL 逻辑示例 (Query Template)
```sql
SELECT
    CASE
        WHEN ad_name ILIKE '%-vid-%' OR ad_name ILIKE '%-video-%' OR ad_name ILIKE '%-aigc-%' THEN 'Video'
        WHEN ad_name ILIKE '%-pic-%' OR ad_name ILIKE '%-picture-%' THEN 'Picture'
        ELSE 'Unknown'
    END AS creative_type,
    SUM(spend) AS spend,
    -- ⚠️ GMV 必须四端累加，详见 analyse-ads-data/SKILL.md
    SUM(COALESCE(web_new_total_fee, 0) + COALESCE(web_old_total_fee, 0) +
        COALESCE(app_new_gmv, 0) + COALESCE(app_old_gmv, 0)) AS total_gmv,
    SUM(total_gmv) / NULLIF(SUM(spend), 0) AS lt_roi,
    -- ... 关联 FT 表计算 28D ROI ...
```
