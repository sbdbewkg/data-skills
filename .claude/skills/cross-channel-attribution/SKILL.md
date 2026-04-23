---
name: cross-channel-attribution
description: 当用户需要进行价值分析、转化对比、渠道贡献分析时使用此 skill。用于从 dws_user_journey_simplification_long 表提取用户旅程数据，基于首次/最后触达进行归因，**支持7/14/28天窗口期**，**跨天转化默认开启**，**默认按分月+半月度展示数据**，支持交叉归因（同时分析引流侧和下单侧），支持半月度时间切片。适用于分析视频广告表现、对比不同月份转化效果、评估各渠道贡献度等场景。
---

# Cross Channel Attribution Skill

专业的用户旅程归因分析工具。

**AI 角色定位**：你是一名**高级价值分析师**，而不仅仅是 SQL 翻译员。你的核心职责是确保数据在引流侧与下单侧之间的逻辑一致性，严禁将已知的付费渠道错误归类为"其他"或"非FB/GG"。

## 何时使用

当用户提到以下内容时，**必须**使用此 skill：

- "价值分析"
- "转化对比"
- "渠道贡献"
- "广告效果"
- "视频广告表现"
- "渠道贡献度"
- "用户旅程"
- "首次触达"
- "最后触达"
- "first touch"
- "last touch"
- "占比情况"
- "流向"
- "交叉"
- 分析不同月份的广告/渠道表现对比
- "上半月" / "下半月" / "半月度"
- "自归因"

## 核心逻辑（基于 QuickBI 生产验证模板）

### 1. 数据来源表

使用 `dws_user_journey_simplification_long` 表：

| 字段类别 | 字段名 | 说明 |
|----------|--------|------|
| 设备ID | `device_info_union_one_id` | 用户设备标识 |
| 订单 | `order_id` | 订单 ID |
| | `order_time` | 订单时间 (UTC) |
| | `total_fee` | 订单金额 |
| | `order_source` | 订单来源（META/GOOGLE/自然流量） |
| | `order_ads_type_first` | **订单广告类型（核心转化渠道）** |
| | `order_ads_type_vid` | 订单素材类型（视频/图片/其他） |
| | `window_period` | 窗口期（固定 '7 Days'） |
| 首次触达 | `time_period_first_touch_event_time` | 首次触达时间 (UTC) |
| | `time_period_first_touch_event_source` | 首次触达来源（META/GOOGLE/自然流量） |
| | `time_period_first_touch_ads_channel` | 首次触达渠道 |
| | `time_period_first_touch_event_ads_type_first` | **首次触达广告类型（核心引流渠道）** |
| | `time_period_first_touch_event_ads_type_vid` | 首次触达素材类型（视频/图片/其他） |
| 最后触达 | `time_period_last_touch_event_time` | 最后触达时间 |
| | `time_period_last_touch_ads_channel` | 最后触达渠道 |

### 2. 核心字段绑定关系（价值分析准则）

**⚠️ 重要：你必须始终保持以下 1:1 逻辑对齐**

| 引流侧（Touch） | 等号 | 下单侧（Order） | 说明 |
|-----------------|------|-----------------|------|
| `time_period_first_touch_event_ads_type_first` | ↔ | `order_ads_type_first` | **核心渠道必须严格对齐** |
| `time_period_first_touch_event_ads_type_vid` | ↔ | `order_ads_type_vid` | 素材维度（次级细分） |

**素材维度说明**：
- `ads_type_vid` 的取值为：`视频` / `图片` / `其他`
- **`其他` = 图片**：在业务语义上，`其他` 等同于图片素材，展示时统一标注为"图片"
- conver 渠道有视频/图片之分；daba/lahuo/Shopping/PMax 的 `ads_type_vid` 全部为"其他"（即图片）
- **自然流量作为首次触达时，`touch_creative` 固定为"其他"**，无法区分素材类型

### 3. 自然流量字段说明

**⚠️ 重要：在当前固定筛选条件下，`非FB/GG` = 自然流量**

```sql
-- 因为 WHERE 条件已限定来源：
AND time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')
AND order_source IN ('META', 'GOOGLE', '自然流量')

-- 所以在查询结果中：
-- order_ads_type_first = '非FB/GG'  →  等价于自然流量下单
-- time_period_first_touch_event_ads_type_first = '非FB/GG'  →  等价于自然流量触达
```

不存在其他来源，`非FB/GG` 就是自然流量，**不要用 `自然流量` 作为字段值过滤**，正确值是 `非FB/GG`。

### 4. 值映射白名单（价值分析准则）

**核心渠道值必须在以下范围内**：

```sql
['daba', 'lahuo', 'conver', 'Brand Seach', 'Non Brand Seach', 'PMax', 'Shopping', '非FB/GG']
```

**严禁出现的错误分类**：
- ❌ 将 `daba` 触达的订单在转化端统计为"其他"
- ❌ 用 `自然流量` 作为 `ads_type_first` 的过滤值（正确值是 `非FB/GG`）
- ❌ 将 `conver` 触达的订单在转化端统计为"其他"

**正确做法**：
- ✅ 如果引流侧是 `daba`，下单侧也应该是 `daba`（自归因）
- ✅ 自然流量用 `非FB/GG` 过滤，不是 `自然流量`
- ✅ 所有付费渠道的订单必须追溯到其真实的转化渠道

### 5. 时间字段说明

数据库存储的时间字段可直接使用，无需偏移。

**重要：所有时间字段查询必须使用 ::text 转换**

```sql
-- 正确写法：时间字段必须转换为 text
time_period_first_touch_event_time::text AS touch_time
order_time::text AS order_time
SUBSTRING(time_period_first_touch_event_time::text, 1, 7) AS touch_month  -- 取月份 "2025-12"
SUBSTRING(time_period_first_touch_event_time::text, 1, 10) AS touch_date  -- 取日期 "2025-12-03"

-- 跨天转化判断也必须使用 ::text
CASE
  WHEN SUBSTRING(time_period_first_touch_event_time::text, 1, 10) = SUBSTRING(order_time::text, 1, 10)
  THEN '当天触达当天下单'
  ELSE '当天触达 非当天下单'
END = '当天触达 非当天下单'
```

### 6. 归因类型

1. **首次触达归因 (First Touch)**: 归因给用户第一次接触的渠道
2. **最后触达归因 (Last Touch)**: 归因给用户最后一次接触的渠道
3. **交叉分析**: 同时分析引流侧（首次触达）和下单侧（最后触达），输出交叉透视表

### 7. 跨天转化（默认开启）

**定义**：当天触达但非当天下单 = 跨天转化

```sql
-- 跨天转化过滤（默认开启）
AND CASE
  WHEN SUBSTRING(time_period_first_touch_event_time::text, 1, 10) = SUBSTRING(order_time::text, 1, 10)
  THEN '当天触达当天下单'
  ELSE '当天触达 非当天下单'
END = '当天触达 非当天下单'
```

**执行逻辑**：
- **默认**：开启过滤（只保留跨天转化）
- **关闭条件**：当用户明确说"全量"、"包含当天"或"关闭跨天过滤"时，移除该条件

### 8. 半月度时间切片

当用户提到"上半月"、"下半月"、"半月度"时，自动应用此切片：

```sql
-- 半月度切片
CASE
  WHEN CAST(SUBSTRING(time_period_first_touch_event_time::text, 9, 2) AS INT) <= 15
  THEN 'First Half'
  ELSE 'Second Half'
END AS half_period
```

### 9. 渠道筛选条件（可自定义）

**⚠️ 重要修正**：引流侧 Source 默认包含自然流量

```sql
-- ==================== 默认筛选条件 ====================
-- 触达侧 Source：默认包含 META, GOOGLE, 自然流量
time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')

-- 下单侧 Source：默认包含 META, GOOGLE, 自然流量
order_source IN ('META', 'GOOGLE', '自然流量')


-- ==================== 自定义选项 ====================
-- 用户可指定仅分析付费渠道：
-- time_period_first_touch_event_source IN ('META', 'GOOGLE')

-- 用户可指定仅分析自然流量触达：
-- time_period_first_touch_event_source = '自然流量'
```

```sql
-- 固定筛选条件（始终包含）
window_period = '7 Days'
AND time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')
AND order_source IN ('META', 'GOOGLE', '自然流量')
```

## 核心逻辑四大支柱

### 支柱1: 强制嵌套架构（避免 -32603 报错）

生成 SQL 时必须严格分层：

```sql
-- 内层：定义渠道别名
SELECT
    SUBSTRING(time_period_first_touch_event_time::text, 1, 7) AS touch_month,
    time_period_first_touch_event_ads_type_first AS touch_channel,
    time_period_first_touch_event_ads_type_vid AS touch_creative,
    order_ads_type_first AS order_channel,
    order_ads_type_vid AS order_creative,
    COUNT(DISTINCT order_id) AS order_count
FROM dws_user_journey_simplification_long
WHERE [固定筛选条件]

-- 中层：GROUP BY 聚合
GROUP BY touch_month, touch_channel, touch_creative, order_channel, order_creative

-- 外层：引用中层别名，执行窗口函数
SELECT
    touch_month,
    touch_channel,
    touch_creative,
    order_channel,
    order_creative,
    order_count,
    total_touch_volume,
    ROUND(order_count * 100.0 / total_touch_volume, 2) AS flow_share_pct
FROM (
    SELECT [中层结果]
    SUM(order_count) OVER (PARTITION BY touch_month, touch_channel, touch_creative) AS total_touch_volume
) sub
```

### 支柱2: 严谨化自归因判定（价值分析核心）

**⚠️ 自归因定义（严格版本）**：

自归因 = 渠道相同 **AND** 素材类型完全相等

- 渠道：`time_period_first_touch_event_ads_type_first = order_ads_type_first`
- 素材：`time_period_first_touch_event_ads_type_vid = order_ads_type_vid`

**不允许助攻转化**：自归因只统计完全匹配的订单，不考虑助攻/自然流量转化。

```sql
-- 严谨自归因判定：渠道+素材完全相等
-- 自归因订单数
SUM(CASE WHEN touch_channel = order_channel AND touch_creative = order_creative THEN order_count ELSE 0 END) AS self_attr_orders

-- 自归因占比 = 自归因订单 / 引流渠道总订单
ROUND(
    SUM(CASE WHEN touch_channel = order_channel AND touch_creative = order_creative THEN order_count ELSE 0 END) * 100.0 /
    SUM(order_count) OVER (PARTITION BY touch_month, touch_channel, touch_creative),
2) AS self_attribution_pct
```

**注意**：此定义下，不再需要 "Self-Attribution" vs "Assisted" 的分类标签，只需直接计算自归因占比。

### 支柱3: 占比位移分析（Share Shift / Delta）

分析重点：不在于订单绝对值的增减，而在于**占比的变化**。

```sql
-- 占比位移计算
flow_share_pct - LAG(flow_share_pct) OVER (
    PARTITION BY touch_channel, touch_creative, order_channel, order_creative
    ORDER BY touch_month
) AS share_delta

-- 价值判定
CASE
    WHEN share_delta > 5 THEN '🟢显著增强'
    WHEN share_delta > 2 THEN '🟡增强'
    WHEN share_delta > -2 THEN '⚪稳定'
    WHEN share_delta > -5 THEN '🟠稀释'
    ELSE '🔴显著下降'
END AS shift_verdict
```

### 支柱4: 自动化分析模板

输出报告时必须包含以下分析维度：

```markdown
### 🔍 收割力迁移洞察

- 如果"自然流量"的自归因占比下降，而"Daba"对自然流量的收割占比上升：
  → 明确指出"付费渠道正在加速收割自然流量"

### 🔍 渠道闭环力监控

- 监控各渠道自归因占比的环比趋势
- 判定渠道独立转化的健康度

### 🔍 占比位移摘要

- 列出 |Δ| > 2pp 的显著变化路径
- 标注增强/稀释方向
```

## 执行步骤

### Step 1: 理解分析需求

1. **确定默认展示模式**：用户未指定时，默认按"分月 + 半月度"展示
2. 确定分析的时间范围（首次触达时间范围）
3. 确定归因类型（引流侧/下单侧/交叉分析）
4. 确定是否需要半月度切片（上半月/下半月）- **默认开启**
5. 确定是否需要精细化广告类型筛选（含素材维度）
6. 确定是否关闭跨天转化（全量数据）
7. **价值对齐**：确认引流侧与下单侧的字段对齐是否正确

### Step 2: 构建 SQL 查询（基于 QuickBI 生产验证）

#### 2.1 固定筛选条件模板

所有查询必须包含以下固定筛选：

```sql
-- ==================== 固定筛选条件（所有查询必须包含）====================
window_period = '{window_period}'  -- 支持 7 Days / 14 Days / 28 Days

-- 触达侧 Source：默认包含自然流量
-- 用户可自定义：如只需付费渠道改为 IN ('META', 'GOOGLE')
time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')

-- 下单侧 Source：默认包含自然流量
-- 用户可自定义
order_source IN ('META', 'GOOGLE', '自然流量')

-- ==================== 跨天转化过滤（默认开启）====================
AND CASE
    WHEN SUBSTRING(time_period_first_touch_event_time::text, 1, 10) = SUBSTRING(order_time::text, 1, 10)
    THEN '当天触达当天下单'
    ELSE '当天触达 非当天下单'
END = '当天触达 非当天下单'
```

#### 2.2 查询类型映射

根据用户需求选择对应查询：

| 需求 | 查询类型 | 说明 |
|------|----------|------|
| **默认（用户未指定）** | **半月度自归因分析** | 自动按分月+半月度展示 |
| "占比情况"、"流向"、"交叉" | **交叉分析** | 同时输出引流侧 + 下单侧 |
| "上半月"、"下半月"、"半月度" | **半月度切片** | 按日期≤15分区 |
| "只看某广告类型" | **精细化筛选** | 复杂广告类型过滤 |
| 仅看"引流贡献" | **引流侧聚合** | 仅按 touch_ads_type 统计 |
| 仅看"下单渠道" | **下单侧聚合** | 仅按 order_ads_type 统计 |
| "流向"、"占比"、"去向" | **引流贡献流向矩阵** | 以引流渠道为分母计算占比 |
| "自归因占比" | **自归因分析** | 含素材维度的自归因判定 |

#### 2.3 自归因占比分析（含素材维度）

**当用户需要分析自归因占比变化时，必须使用此查询。**

核心逻辑：
- 判定自归因：touch_channel = order_channel **AND** touch_creative = order_creative
- 计算自归因占比 (Self- Attribution %)
- 按素材类型细分

```sql
-- 参数化变量：{start_month} {end_month}（格式：'YYYY-MM'）
-- 自归因占比 + 素材维度分析

WITH flow_base AS (
    -- 内层：定义渠道和素材别名
    SELECT
        SUBSTRING(time_period_first_touch_event_time::text, 1, 7) AS touch_month,
        time_period_first_touch_event_ads_type_first AS touch_channel,
        time_period_first_touch_event_ads_type_vid AS touch_creative,
        order_ads_type_first AS order_channel,
        order_ads_type_vid AS order_creative,
        COUNT(DISTINCT order_id) AS order_count
    FROM dws_user_journey_simplification_long
    WHERE
        window_period = '7 Days'
        AND time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')
        AND order_source IN ('META', 'GOOGLE', '自然流量')
        AND time_period_first_touch_event_ads_type_first NOT IN ('自然流量', '非FB/GG')
        AND SUBSTRING(time_period_first_touch_event_time::text, 1, 7) >= '{start_month}'
        AND SUBSTRING(time_period_first_touch_event_time::text, 1, 7) <= '{end_month}'
        AND CASE
            WHEN SUBSTRING(time_period_first_touch_event_time::text, 1, 10) = SUBSTRING(order_time::text, 1, 10)
            THEN '当天触达当天下单'
            ELSE '当天触达 非当天下单'
        END = '当天触达 非当天下单'
    GROUP BY 1, 2, 3, 4, 5
),
flow_mid AS (
    -- 中层：聚合 + 自归因判定（严谨版：渠道+素材同时匹配）
    SELECT
        touch_month,
        touch_channel,
        touch_creative,
        SUM(order_count) AS total_touch_volume,
        SUM(CASE WHEN touch_channel = order_channel AND touch_creative = order_creative THEN order_count ELSE 0 END) AS self_attr_orders
    FROM flow_base
    GROUP BY touch_month, touch_channel, touch_creative
),
flow_with_pct AS (
    -- 外层：占比计算
    SELECT
        touch_month,
        touch_channel,
        touch_creative,
        total_touch_volume,
        self_attr_orders,
        ROUND(self_attr_orders * 100.0 / NULLIF(total_touch_volume, 0), 2) AS self_attribution_pct
    FROM flow_mid
)
SELECT
    touch_month,
    touch_channel,
    touch_creative,
    total_touch_volume,
    self_attr_orders,
    self_attribution_pct
FROM flow_with_pct
ORDER BY touch_month DESC, touch_channel, touch_creative, self_attribution_pct DESC;
```

#### 2.4 半月度自归因趋势分析

**当用户需要按上下半月分析自归因趋势时**：

```sql
-- 半月度自归因分析

WITH flow_base AS (
    SELECT
        window_period,
        SUBSTRING(time_period_first_touch_event_time::text, 1, 7) AS touch_month,
        CASE
            WHEN CAST(SUBSTRING(time_period_first_touch_event_time::text, 9, 2) AS INT) <= 15
            THEN 'First Half'
            ELSE 'Second Half'
        END AS half_period,
        time_period_first_touch_event_ads_type_first AS touch_channel,
        time_period_first_touch_event_ads_type_vid AS touch_creative,
        order_ads_type_first AS order_channel,
        order_ads_type_vid AS order_creative,
        COUNT(DISTINCT order_id) AS order_count
    FROM dws_user_journey_simplification_long
    WHERE
        window_period = '7 Days'
        AND time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')
        AND order_source IN ('META', 'GOOGLE', '自然流量')
        AND time_period_first_touch_event_ads_type_first NOT IN ('自然流量', '非FB/GG')
        AND SUBSTRING(time_period_first_touch_event_time::text, 1, 7) >= '2025-09'
        AND SUBSTRING(time_period_first_touch_event_time::text, 1, 7) <= '2026-02'
        AND SUBSTRING(time_period_first_touch_event_time::text, 1, 10) != SUBSTRING(order_time::text, 1, 10)
    GROUP BY 1, 2, 3, 4, 5, 6, 7
)
SELECT
    touch_month,
    half_period,
    touch_channel,
    touch_creative,
    SUM(order_count) AS total_touch_orders,
    SUM(CASE WHEN touch_channel = order_channel AND touch_creative = order_creative THEN order_count ELSE 0 END) AS self_attr_orders,
    ROUND(
        SUM(CASE WHEN touch_channel = order_channel AND touch_creative = order_creative THEN order_count ELSE 0 END) * 100.0 /
        NULLIF(SUM(order_count), 0), 2
    ) AS self_attribution_pct
FROM flow_base
GROUP BY 1, 2, 3, 4
ORDER BY window_period, touch_month DESC, half_period, touch_channel, touch_creative
```

#### 2.5 交叉分析表（引流 × 下单）

**当用户询问"流向"、"占比"时，必须使用此查询**：

```sql
-- 交叉分析：横轴=下单渠道，纵轴=引流渠道

SELECT
    time_period_first_touch_event_ads_type_first AS touch_channel,
    time_period_first_touch_event_ads_type_vid AS touch_creative,
    SUBSTRING(time_period_first_touch_event_time::text, 1, 7) AS touch_month,
    order_ads_type_first AS order_channel,
    order_ads_type_vid AS order_creative,
    COUNT(DISTINCT order_id) AS order_count
FROM dws_user_journey_simplification_long
WHERE
    window_period = '7 Days'
    AND time_period_first_touch_event_source IN ('META', 'GOOGLE', '自然流量')
    AND order_source IN ('META', 'GOOGLE', '自然流量')
    AND SUBSTRING(time_period_first_touch_event_time::text, 1, 7) >= '{start_month}'
    AND SUBSTRING(time_period_first_touch_event_time::text, 1, 7) <= '{end_month}'
    AND CASE
        WHEN SUBSTRING(time_period_first_touch_event_time::text, 1, 10) = SUBSTRING(order_time::text, 1, 10)
        THEN '当天触达当天下单'
        ELSE '当天触达 非当天下单'
    END = '当天触达 非当天下单'
GROUP BY 1, 2, 3, 4, 5
ORDER BY touch_month, order_count DESC;
```

## 输出要求

### ⚠️ 默认展示模式：分月 + 半月度

**⚠️ 重要**：当用户**未明确指定**展示方式时，默认按以下维度展示数据：

| 维度 | 说明 | 示例 |
|------|------|------|
| **分月** | 按月份汇总 | 2025-09, 2025-10, 2025-11... |
| **分上下半周** | 按半月度切片 | First Half (1-15日), Second Half (16-月末) |

这意味着：
- 默认执行**半月度自归因分析**（2.4 模板）
- 输出按 `touch_month` + `half_period` 双重分组
- 如果用户明确说"按天"、"只看某月"等，则按用户要求执行

### ⚠️ 报告限制条件（每次报告必须声明）

每次生成分析报告时，**必须在报告正文最开头**用以下格式列出本次查询的实际筛选条件，让用户清楚知道数据口径：

```
## 📋 本次查询条件
- **分析时间范围**：xxxx年xx月 ～ xxxx年xx月
- **窗口期**：7 Days / 14 Days / 28 Days
- **跨天转化**：开启（仅保留 touch日期 ≠ order日期）
- **触达侧来源**：META, GOOGLE, 自然流量
- **下单侧来源**：META, GOOGLE, 自然流量
- **引流渠道筛选**：daba / lahuo / conver / PMax / Shopping（或用户指定）
- **素材类型**：视频 / 图片（其他=图片）
```

以上各项根据实际查询动态填写，不要写默认值，要写本次真实使用的值。

### 必须包含

1. **交叉分析表**（默认）：横轴为下单渠道，纵轴为引流渠道，单元格为订单量
2. **占比计算**：引流侧占比、下单侧占比、自归因占比
3. **素材维度**：当素材类型不同时，必须分开统计
4. **半月度对比**（当用户提及时）：上半月 vs 下半月趋势
5. **价值洞察**：作为分析师，指出数据中的异常或显著变化

### 趋势总结模板

```
### 🔍 渠道流向洞察

1. **daba → 自然流量**: 占比最高，说明 daba 引流用户最终多通过自然流量完成转化
2. **conver 视频 → conver 视频**: 自归因闭环转化能力强，1月自归因占比达39%
3. **Shopping 下滑**: 自归因占比从35%降至26%，需关注素材策略
```

## 数据库连接

使用 `data_us_holo_postgresql` MCP 连接数据库执行查询。

连接信息已在 OpenCode 配置中定义。

## 注意事项

### 底层硬性约束（必须遵守）

| 约束项 | 规范 | 来源 |
|--------|------|------|
| **时间字段** | 必须使用 `::text` 转换 | 硬性规定 |
| **窗口期** | 支持 7/14/28 Days（用户指定） | 可选参数 |
| **触达Source** | 默认 IN ('META', 'GOOGLE', '自然流量') | 可自定义 |
| **下单Source** | 默认 IN ('META', 'GOOGLE', '自然流量') | 可自定义 |
| **渠道过滤** | 无（用户可自定义） | 可选 |
| **转化判定** | 非当天转化（默认开启） | 硬性规定 |
| **自归因判定** | touch_channel=order_channel AND touch_creative=order_creative | 硬性规定 |

### SQL 构建规范

1. **时间字段**：所有时间字段必须使用 `::text` 转换
   - `time_period_first_touch_event_time::text AS touch_time`
   - `order_time::text AS order_time`
2. **日期提取**：使用 `SUBSTRING(time::text, 1, 7)` 取月份
3. **跨天过滤**：`SUBSTRING(touch_time::text, 1, 10) != SUBSTRING(order_time::text, 1, 10)`
4. **半月度切片**：`CASE WHEN CAST(SUBSTRING(time::text, 9, 2) AS INT) <= 15 THEN 'First Half' ELSE 'Second Half' END`
5. **自归因判定**：`touch_channel = order_channel AND touch_creative = order_creative`

### 价值分析准则

1. **字段对齐**：始终保持 `touch_ads_type_first ↔ order_ads_type_first` 的 1:1 逻辑
2. **素材类型**：`其他` = 图片，展示时统一写"图片"
3. **趋势异常**：识别突变月份并标注

### 价值判定框架

**自归因率判定（以9月为基准）**：

| 与基准相比变化 | 判定 | 建议 |
|---------------|------|------|
| > +8pp | 🔴 严重过渡投放 | 减量20-30% |
| +4 ~ +8pp | 🟡 过渡投放 | 减量10-20% 或观察 |
| -2 ~ +4pp | ⚪ 正常 | 保持 |
| < -4pp | 🟢 效率改善 | 可加量 |

**双维度综合判定（自归因率 + 蚕食自然流量）**：

| 自归因率 | 蚕食自然流量 | 价值判定 | 建议 |
|----------|-------------|----------|------|
| ↑ 上升 | ↑ 上升 | 🔴 低价值：双高，广告"自己吃自己" | 立即减量 |
| ↑ 上升 | ↓ 下降 | 🟡 潜力价值但能带动自然流量 | 适度降频 |
| ↓ 下降 | ↑ 上升 | 🟠 辅助价值但蚕食自然流量 | 观察 |
| ↓ 下降 | ↓ 下降 | 🟢 高价值：助攻增强且减少蚕食 | 加量 |

### 跨天转化开关

- **默认**：开启（只保留跨天转化）
- **关闭条件**：当用户说"全量"、"包含当天"、"关闭跨天过滤"时，移除该 WHERE 条件

### 数据脱敏

展示时避免泄露敏感用户信息
