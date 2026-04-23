# Cider Ads Agent - Growth & Improvements Tracker (成长文档)

## 概述 (Overview)
记录广告分析 Agent 在任务执行中遇到的数据缺失、技术瓶颈及待优化项。每项任务前应回看此文档，确认瓶颈是否已解决。

## 待办项 (TODOs & Missing Data)

| 日期 | 类型 | 描述 | 状态 | 预期产出/TODO |
| :--- | :--- | :--- | :--- | :--- |
| 2026-03-09 | 数据缺失 | **SKU/库存明细表** (Missing Table) | 🔴 Pending | 确认包含 `order_id` 与 `sku_id` 关联的表名。目标：支持“ROI 波动 -> SKU 缺货”的闭环诊断。 |
| 2026-03-09 | 数据缺失 | **素材元数据标签** (Creative Meta) | 🔴 Pending | 建议接入 `post_id` 对应的 Hook 率、时长、创意标签（如：甜酷、美式复古）。目前只能靠 ad_name 模糊匹配。 |
| 2026-03-12 | 数据缺失 | **Google Ads 消耗底表** (Google Spend Data) | 🔴 Pending | 寻找并连接 Google 原始消耗表（如 `ods_google_ads_report` 或 `dw_gg_ads_...`）。目标：计算 Google Shopping 真实 LT/FT ROI，消除当前与 Meta 数据错位导致的虚高 ROI（77.96）。当前仅能看到归因产出（GMV $3,528万/6个月），但无消耗分母。**ACEA 分析显示 Google Shopping 的 SA% (46.4%) 和 OH% (38.0%) 均为全渠道最优，具备极高增量价值，急需补全 ROI 指标以支持预算决策。** |
| 2026-03-09 | 数据缺失 | **大盘 Benchmarks** (Market Trend) | 🔴 Pending | 引入同一 Country/Account 下的平均 CPM 作为波动对照组。目标：区分是个案还是大盘涨价。 |
| 2026-03-09 | 数据缺失 | **负面反馈数据** (Sentiment) | 🔴 Pending | 接入 Meta 接口的 `negative_feedback` 指标。目标：预判广告素材的生命周期（Creative Fatigue）。 |
| 2026-03-09 | 流程优化 | **4层诊断法自动化** (Skill Optimization) | 🟡 In Progress | 已建立 `diagnose-ads-fluctuation` skill，但 SQL 模版仍需根据不同 Objective 进行精细化适配。 |

## 已解决项 (Resolved)

| 日期 | 描述 | 解决方式 |
| :--- | :--- | :--- |
| 2026-03-09 | 归因口径不一 (LT vs FT) | 建立 `analyse-ads-attribution` skill 规范 LT 24H 与 FT 28D 的对比逻辑。 |
| 2026-03-09 | 素材分类规则不一 | 确立 `AIGC = Video` 核心准则，并在所有分析 SQL 中强制执行。 |

---
**提示**：运行任务前，请先调用 `manage-improvements` skill 更新或同步此文档。
