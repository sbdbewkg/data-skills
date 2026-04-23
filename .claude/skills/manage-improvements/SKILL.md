# Skill: Manage Improvements & Growth Tracker

## 概述 (Overview)
本技能用于维护 `IMPROVEMENTS.md` 成长文档。当用户提出新需求无法满足，或分析中发现数据/技术瓶颈时，必须调用此技能进行记录。

## 执行准则 (Execution Guidelines)
1. **任务前置 (Pre-task Check)**: 每次执行分析任务前，必须回看 `IMPROVEMENTS.md`，确认该任务所需的历史瓶颈是否已标记为 `Resolved`。
2. **记录时机 (When to Record)**:
   - 遇到 SQL 查询不到核心业务表（如 SKU、库存表）。
   - 用户提出新的业务规则（如“拉活账户”逻辑更新）。
   - 系统报错或归因逻辑异常。
3. **状态更新 (State Management)**:
   - 遇到新问题 -> `🔴 Pending`。
   - 正在尝试解决 -> `🟡 In Progress`。
   - 已通过 SQL 验证或用户确认 -> `🟢 Resolved`。

## 操作指令 (Operation Commands)
- **Add**: 将新问题加入表格，包含日期和预期产出。
- **Mark**: 将已解决的问题从 `Pending` 修改为 `Resolved`，并记录解决方式。
- **Summarize**: 总结当前所有 Pending 状态的瓶颈，并向用户报告。

## 文档结构模版 (Template)
| 日期 | 类型 | 描述 | 状态 | 预期产出/TODO |
| :--- | :--- | :--- | :--- | :--- |
| YYYY-MM-DD | [数据/规则/流程] | 问题描述 | [🔴/🟡/🟢] | 具体 TODO |
