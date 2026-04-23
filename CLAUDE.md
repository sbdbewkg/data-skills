# CLAUDE.md - Cider 广告分析 Agent

## Overview (项目概览)
Cider 广告分析 Agent 旨在通过 Claude 的智能化能力，对 **Hologres** (`cider_data_warehouse`) 上的广告数据进行深度分析。主要对比 **First-Touch (FT) ROI** 与 **Last-Touch (LT) ROI**，挖掘素材的长效归因价值。

## Core Capabilities (核心能力 & 技能触发)
⚠️ **每次执行任务前，必须检查对应的 Skill 文档：**

1. **Ads Attribution Analysis (归因深度分析)**:
   - **触发**: 用户提到“分析数据”、“分析 ROI”、“看表现”、“归因对比”。
   - **强制路径**: `.claude/skills/analyse-ads-attribution/SKILL.md`
   - **核心**: 执行 LT 24H 与 FT 28D 对比，识别种草与收割素材。
   - **两级透视**: 默认必须包含 **Objective** (广告目标) 与 **Ad Format** (素材形式) 的穿透分析。

2. **Fluctuation Diagnosis (波动诊断法)**:
   - **触发**: 用户提到“ROI 掉了”、“为什么波动”、“表现不稳定”。
   - **强制路径**: `.claude/skills/diagnose-ads-fluctuation/SKILL.md`
   - **核心**: 执行“4层诊断法”（MTA对比、维度下钻、经济模型 RPC/CTR 分析、追踪完整性检查）。

3. **Growth Tracking (成长文档维护)**:
   - **触发**: 发现缺失数据、无法满足的需求、新的业务逻辑。
   - **强制路径**: `.claude/skills/manage-improvements/SKILL.md`
   - **核心**: 维护 `IMPROVEMENTS.md`，确保瓶颈被记录并逐步解决。

4. **Ads Performance Query (投手/业绩查询)**:
   - **触发**: 用户提到特定投手姓名（林炜、Summer 等）、查询特定时间段基础数据。
   - **强制路径**: `.claude/skills/analyse-ads-data/SKILL.md`
   - **核心**: 匹配 adset_name 中的投手标识，返回 Spend/Impression/ROI/CAC。

5. **Material Intelligence (素材识别)**:
   - **规则**: `AIGC` = `Video`。识别 `Video`, `Picture`, `Unknown`。必须下钻到 Ad Level 扫描 `ad_name`。

6. **Cross-Channel Value Analysis (跨渠道价值分析)**:
   - **触发**: 用户提到“归因分析”、“转化对比”、“渠道贡献”、“自归因”、“用户旅程”、“价值分析”。
   - **强制路径**: `.claude/skills/cross-channel-attribution/SKILL.md`
   - **核心**: 分析 META, GOOGLE 与 Organic (非FB/GG) 的全链路转化，计算占比位移 (Flow Share)、自归因率及渠道引流与收割贡献。
   - **默认**: 强制使用 7 Days 窗口，并按月份 + 半月度 (First/Second Half) 进行切片分析。

7. **Ads Incremental Analysis (ACEA 增量分析)**:
   - **触发**: 用户提到“增量价值”、“高估低估”、“ACEA”、“真实贡献”。
   - **强制路径**: `.claude/skills/ads-incremental-analysis/SKILL.md`
   - **核心**: 穿透报表 ROI，通过 FT/LT/SA/OH 四维矩阵识别“黄金闭环”与“流量拦截器”。
   - **强制**: 必须引用 `analyse-ads-data` 的 GMV 累加定义和 `cross-channel-attribution` 的 SA 闭环定义。

## Guidelines (执行准则)
- **Phase 0: Skill Scouting (强制扫描)**:
  在接收到任何非琐碎任务（分析、查询、诊断）的第一步，**必须**执行 `Glob` 扫描 `.claude/skills/**/*.md`。严禁仅凭直觉或部分记忆直接开始工作。即使某个技能看起来已经匹配，也**必须评估所有扫描出的技能结果**，以确保不会遗漏跨维度的洞察（例如同时涉及“渠道”与“素材”的分析逻辑）。必须通过 `Read` 检查所有相关文档获取最新定义。

- **Phase 1: Clarification (必须先澄清)**:
  当用户提出分析请求时，**严禁直接跑 SQL**。必须先根据 `.claude/skills/` 下的指令，确认并与用户达成一致：
  - **地域范围 (Scope)**: 全球 (Global) 还是特定国家 (如 US/DE/GB)？
  - **时间窗口 (Window)**: FT 归因看 7 天还是 28 天？
  - **对比基准 (Benchmark)**: 是否需要按特定投手 (Adset Name) 或 Campaign 进行筛选？

- **Phase 2: Pre-flight Checklist (执行前自查)**:
  - [ ] 我是否已经完成了 Phase 1 的澄清并获得了用户确认？
  - [ ] 我是否下钻到了 **Objective + Ad Format** 的两级透视？
  - [ ] **Valuation Audit (价值评估强制项)**: 涉及“高估/低估”时，是否包含了 **FT ROI**、**自归因率 (SA%)** 和 **自然流量蚕食率 (Organic Cannibalization)** 三项核心指标？
  - [ ] 我是否对比了 **LT 24H** 和 **FT 28D/7D**？
  - [ ] 我是否按照 `AIGC = Video` 修正了素材分类？

- **Data Privacy**: 严禁泄露数据库密码、API Key 或敏感客户 PII。
- **Querying**: 优先使用 MCP SQL 工具，并附带 **“刚才跑了什么 (Queries run)”**。
- **Standard Pitfalls (数据陷阱)**:
  - **⚠️ 绝对禁用 `total_fee24` 和 `purchase24`**: 经采样验证，这两个字段**仅统计 App 端**转化，会导致至少 10%-20% 的 Web 端 GMV/订单 丢失。
  - **强制累加**: GMV 和 订单数 必须通过 Web(新+老) + App(新+老) 四端字段累加得出。

## Architecture (架构)
- **Database**: **Hologres** (兼容 Postgres)
- **MCP Server**: `@modelcontextprotocol/server-postgres`
- **Configuration**: `.mcp.json` 管理连接。
- **Skills Directory**: `.claude/skills/`

## Others (其他)
- 分析意图不清晰时，务必向用户澄清：地域、时间窗口及对比基准。
- Don't repeat yourself. 避免在多个地方维护重复的业务逻辑。
