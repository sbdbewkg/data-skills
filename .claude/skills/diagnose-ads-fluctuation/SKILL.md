# Skill: Diagnose Ad Performance Fluctuation (4-Layer Diagnostic)

## 概述 (Overview)
本技能用于深度诊断广告表现（ROI/Spend）的剧烈波动。通过“4层诊断法”层层剥茧，快速定位是前端流量（CTR/CPM）、后端转化（CVR/AOV）、归因缺失（Link_ID Gap）还是外部竞争（Benchmark）导致的问题。

## 执行准则 (Execution Guidelines)
⚠️ **在分析波动前，必须根据数据账龄 (Data Age) 选择合适的指标，严禁“归因时效错配”：**

### Layer 0: 归因时效自查 (Attribution Maturity) - **CRITICAL**
- **原则**: 严禁使用“未成熟”的长效归因指标来衡量“近期”异动。
- **准则**:
  - **T+0 ~ T+2 (近期异动)**: 核心关注 **LT 24H ROI**, **CTR**, **CPM**, **CPC**。**绝对禁止**参考 FT 28D，因为回填不足会导致严重的负向偏差。
  - **T+3 ~ T+14 (过渡期)**: 可引入 FT 7D 参考，但仍以 LT 表现及前端 Unit Economics 为主。
  - **T+28+ (远期复盘)**: 此时 FT 28D 归因已稳定，可用于评估素材的长效种草资产价值。

### Layer 1: MTA 对比 (种草 vs 收割)
- **目的**: 区分该视频在波动期内是“收割失效”还是“长效种草”。
- **SQL 逻辑**: 仅在数据账龄 > 14天时，关联 `bi_warehouse_dw_fb_w2p_country_roi_hourly` (LT 24H) 与 `dws_user_journey_simplification_long` (FT 28D)。
- **洞察**: 如果 FT ROI 稳定但 LT ROI 下降，说明素材在积累心智，而非效率降低。对于 T+2 以内的异动，若 LT ROI 波动，应直接跳转至 Layer 3 检查前端指标。

### Layer 2: 维度穿透 (Dimensions)
- **下钻路径**: **Objective (CONV/DABA) -> Ad Format (Video/Picture)**。
- **关键规则**: 遵循 `AIGC = Video` 规则。

### Layer 3: 经济模型 (Unit Economics)
- **核心指标**:
  - **ECAC/EROI**: 使用 `bi_warehouse_ods_w2p_coef_fb` 系数进行校准。
  - **RPC (Revenue Per Click)**: 诊断转化效率的关键。
- **诊断逻辑**:
  - `CTR 稳, RPC 降` -> 后端问题（SKU 缺货、价格变动、支付链路）。
  - `CPM 升, CTR 降` -> 前端问题（素材疲劳、人群包竞争、频次过高）。

### Layer 4: 追踪完整性 (Data Integrity)
- **指标**: **Link_ID Fill Rate** (关联订单量 / 总订单量)。
- **逻辑**: 如果波动日伴随填充率骤降，则暴跌是“归因故障”而非“业务波动”。

## 推荐 SQL 模版
```sql
WITH ad_stats AS (
    SELECT report_date::date as dt, SUM(spend) as spend, SUM(total_fee24) as lt_gmv, SUM(link_click) as clicks, SUM(impression) as imps
    FROM bi_warehouse_dw_fb_w2p_country_roi_hourly
    WHERE ad_id = '{target_ad_id}' AND report_date::date BETWEEN '{start}' AND '{end}'
    GROUP BY 1
),
ft_stats AS (
    SELECT time_period_first_touch_event_time::date as dt, SUM(total_fee) as ft_gmv
    FROM dws_user_journey_simplification_long
    WHERE time_period_first_touch_link_id = '{link_id}' AND window_period = '28 Days'
    GROUP BY 1
)
SELECT a.dt, a.lt_gmv/a.spend as lt_roi, f.ft_gmv/a.spend as ft_roi, a.lt_gmv/a.clicks as rpc, a.clicks/a.imps as ctr
FROM ad_stats a LEFT JOIN ft_stats f ON a.dt = f.dt;
```

## 业务决策逻辑
1. **AOV 垂直跌落**: 检查视频关联的 Top SKU 是否缺货。
2. **CPC 垂直跳涨**: 检查该区域（Country）大盘 CPM 是否受竞对或节假日干扰。
3. **FT 增益率 (>2x)**: 即使 LT ROI 低于 KPI，若 FT 增益强劲，建议维持投放。
