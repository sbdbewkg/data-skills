# Cider 广告分析 Agent (Cider Ads Analysis Agent)

## 概述 (Overview)
本仓库用于管理 Cider 广告数据分析的相关 **Skills**、**MCP 配置** 以及 **数据模型**。通过 Claude Agent 与 **Hologres** 数据库的联动，实现自动化、多维度的 ROI 和 CAC 分析。


## 核心功能 (Core Features)
1. **Ads Attribution Analysis**: 深入对比 LT 24H 与 FT 28D 归因。
2. **Material Intelligence**: 自动识别 AIGC、视频、图片等素材类型的获客价值。
3. **Data Warehouse Integration**: 无缝对接 AWS 上的 `cider_data_warehouse` (Hologres)。

## 目录结构 (Project Structure)
- `.claude/skills/`: 沉淀业务逻辑的核心 Skill 文档。
- `.mcp.json.sample`: 数据库连接配置示例。
- `CLAUDE.md`: 项目规范与运行指南。
