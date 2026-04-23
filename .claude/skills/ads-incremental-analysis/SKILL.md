---
name: ads-incremental-analysis
description: 广告增量价值分析 Skill (ACEA 方法论)。通过 FT/LT ROI、自归因率 (SA%) 和 自然流量蚕食率 (OH%) 对广告进行深度“脱水”分析。识别真正创造生意增量的“黄金闭环”素材，剔除高估的“流量拦截器”。
---

# Ads Incremental Value Analysis (ACEA 方法论)

作为**高级广告价值分析师**，你的职责是穿透报表 ROI 的幻觉，通过四个核心维度（FT, LT, SA, OH）评估广告的**真实增量价值 (Incrementality)**。

## 🚨 强制数据对齐准则 (Data Compliance)

**执行 ACEA 分析前，必须无条件遵循以下两个核心 Skill 的底层定义：**

### 1. 引用 `analyse-ads-data` (数据基准)
- **GMV 绝对定义**: 必须使用 `web_new_total_fee + web_old_total_fee + app_new_gmv + app_old_gmv` 计算 LT GMV。
- **🚫 算法风险**: 严禁直接读取 `total_fee24` 或 `purchase24`，任何此类行为将被视为分析事故。
- **CAC 定义**: 必须使用四端新客订单累加作为分母。

### 2. 引用 `cross-channel-attribution` (归因基准)
- **SA% (自归因) 定义**: 必须严格遵循“支柱2”的 1:1 逻辑对齐：
  - `touch_channel = order_channel`
  - `touch_creative = order_creative`
- **自然流量定义**: `非FB/GG` 即为自然流量，严禁在 `ads_type_first` 字段中使用 `自然流量` 字符串进行过滤。
- **素材清洗**: 所有 `其他` 必须统一清洗为 `图片` 后再进行匹配。

## 📊 五大分析场景矩阵 (ACEA Matrix)

| 场景 | 指标特征 | 价值判定 | 战略建议 |
| :--- | :--- | :--- | :--- |
| **场景 A: 黄金闭环** | FT高 / LT高 / SA高 / OH低 | 🟢 **极致低估** | **无限加量**。这是最实的增量，复刻其基因。 |
| **场景 B: 深潜种草** | FT高 / LT低 / SA低 / OH低 | 🟢 **潜力拉新** | **预算保护**。不按 LT 考核，是付费生态的源头。 |
| **场景 C: 流量拦截** | FT高 / LT高 / SA低 / OH高 | 🔴 **严重高估** | **缩减/排除**。拦截自然流量的存量用户，水分极大。 |
| **场景 D: 精准收割** | FT低 / LT高 / SA高 / OH低 | 🟡 **末端守门** | **控频投放**。作为重定向存在，确保转化闭环。 |
| **场景 E: 效能衰退** | 趋势: SA% ↓ / OH% ↑ | 🟠 **风控预警** | **更换素材**。素材失去独立性，开始退化为拦截自然。 |

---

## 🧮 增量加权 ROI 计算 (脱水公式)

为了评估真实净贡献，必须执行以下计算：

$$ \text{Incremental ROI} = \text{FT ROI} \times (1 - \text{OH}\%) $$

---

## 🛠 执行步骤 (Workflow)

1. **Step 1: 基础对齐**
   - 从 `bi_warehouse_dw_fb_w2p_country_roi_hourly` 获取 `spend` 和 `LT GMV`。
   - 从 `dws_user_journey_simplification_long` 获取 `FT GMV`、`SA 订单` 和 `OH 订单`。
   - 必须使用 `link_id` 进行关联以确保 Ad Level 的精确对齐。

2. **Step 2: 矩阵分类**
   - 将广告按上述 5 大场景进行归类。
   - 特别标注 `SA% > 35%` 和 `OH% > 55%` 的极端案例。

3. **Step 3: 诊断报告**
   - 必须输出包含 **Spend, LT ROI, FT ROI, SA%, OH%** 的完整表格。
   - 给出基于“增量加权 ROI”的加减量建议。

---

## ⚠️ 业务禁忌 (Pitfalls)
- ❌ 严禁在 OH% 未知的情况下建议加量。
- ❌ 严禁仅因 LT ROI 低而杀掉 SA% 高且 OH% 低的视频素材。
- ❌ 严禁将 `非FB/GG` 计入自归因逻辑。
