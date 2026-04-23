# 广告系统逻辑配置规范 (V2.5 - 结构化分析版)

---

## 一、 投手维度 (Pitcher) - [核心：责任归属]
*   **字段名称**：`author`
*   **判定逻辑**：基于 `userId` / `uid` 进行映射。
*   **执行准则**：
    *   复用现有 `author` 字段，通过 `userId` 刷新历史数据。
    *   **MECE 覆盖**：每个广告 ID 必须对应一个明确的 `author`，未知 UID 标记为 `system_default`。

---

## 二、 业务属性 (Business Objective) - [核心：增量来源]
*   **字段名称**：`campaign_business_type`
*   **判定逻辑**：
    1.  **Retention (拉活)**：账户 ID 为 `blu-app-2`。
    2.  **UA (拉新)**：除上述账户外的所有其他账户。
*   **MECE 覆盖**：按账户维度切分，不存在中间地带。

---

## 三、 流量去向 (Destination Type) - [核心：ROI 归因逻辑]
针对 **W2P (Web-to-App)** 激进引导场景进行专门优化：

| 类型 | 判定特征 | 归因口径 |
| :--- | :--- | :--- |
| **Web** | 落地页为官网，无明显强引流下载弹窗/按钮 | 仅计算 Web GMV |
| **App** | 直接跳转 App Store 或 DeepLink 唤起 | 仅计算 App GMV |
| **W2P** | 落地页含有“强引导/拦截式”下载按钮 (根据 URL 参数或特定 H5 路径识别) | **Web GMV + App GMV (综合 ROI)** |

---

## 四、 广告类型 (Ad Type) - [核心：投放产品线]
根据特征参数组合进行判定：

| 广告类型 | 判定特征 (Conditions) |
| :--- | :--- |
| **DABA** | 存在 `catalog_id` (使用目录/动态素材) |
| **REACH** | 不存在 `catalog_id` **且** `object` = `OUTCOME_AWARENESS` **且** `goal` = `REACH` |
| **CONVER** | 排除 DABA 和 REACH 后的所有情况 (包含 Sales, Traffic, Link_Clicks) |

---

## 五、 投放模式 (Delivery Mode) - [核心：系统自动化程度]
*   **字段名称**：`delivery_mode`
*   **判定逻辑**：
    *   **ASC**：Meta 接口返回 `smart_promotion_type` 为 `advantage_plus_shopping_campaign` 或 Campaign 命名包含 `_ASC_`。
    *   **Standard**：常规广告。

---

## 六、 展现形式 (Ad Format) - [核心：用户交互界面]
*   **字段名称**：`display_format`
*   **判定逻辑**：
    1.  **Carousel**：物料包含多张图片/视频（轮播图）。
    2.  **Collection**：精品栏广告（主图+下方商品列表）。
    3.  **Single**：单图或单视频。
    4.  **Unknown**：无法识别的第三方格式。

---

## 七、 素材类型 (Creative Type) - [核心：内容形态]
*注：按照 `AIGC` = `video` 逻辑修正。*

1.  **DABA 广告**：统一标记为 `none` (因其随用户兴趣动态生成)。
2.  **CONVER / REACH 广告**：
    *   **Video (视频)**：符合以下任一即是：
        *   `postAdParam` 不为空 (红人帖子默认视频)。
        *   `videoId` / `videoName` (含 `AIGC` 关键词) / `videoIds` 不为空。
        *   Carousel 轮播中包含至少一个视频。
    *   **Image (图片)**：不符合 Video 逻辑，且 `imageIds` / `imageNames` 不为空。
    *   **Other (其他)**：非视频非图片，如 Plain Text（极少）。
    *   **None**：无素材 ID (仅出现在异常数据中)。

---

## 八、 PA 标识 (Partnership Ads) - [核心：达人背书]
*   **判定标准**：
    *   **PA 广告**：Partnership 开关 = `ON`。
    *   **Normal 广告**：Partnership 开关 = `OFF`。

---

## 九、 投放策略层 (Strategy Layer) - [辅助：排除干扰变量]
*核心：通过低基数 (Low Cardinality) 枚举值对齐归因分析口径。*

| 字段名称 | 判定逻辑优先级 (命名关键词扫描) | 枚举值范围 |
| :--- | :--- | :--- |
| **`ad_phase`** (生命周期) | 1. 包含 `ce`, `测`, `new` $\rightarrow$ `Testing`<br>2. 包含 `kl`, `kuo`, `扩`, `xfjh` $\rightarrow$ `Scaling`<br>3. 包含 `stable`, `chongtou` $\rightarrow$ `Stable` | `Testing`, `Scaling`, `Stable`, `Other` |
| **`aspect_ratio`** (画面比例) | 1. 包含 `916`, `9-16`, `vertical` $\rightarrow$ `Vertical`<br>2. 包含 `11`, `1-1`, `square` $\rightarrow$ `Square`<br>3. 包含 `lun`, `carousel` $\rightarrow$ `Carousel` | `Vertical`, `Square`, `Carousel`, `Other` |
| **`opt_logic`** (优化口径) | 1. 包含 `7dc`, `7dclick` $\rightarrow$ `7DC`<br>2. 包含 `1dc`, `1dclick` $\rightarrow$ `1DC`<br>3. 包含 `vo`, `value`, `roas` $\rightarrow$ `Value_Opt` | `7DC`, `1DC`, `Value_Opt`, `Standard` |

---
**版本说明**：本规范 V2.5 结合了 500+ 采样数据的基数压力测试，剔除了高噪音维度，保留了对 ROI 分析最具策略价值的 9 大核心维度。
