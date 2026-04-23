# US Product Analysis — Claude Code 项目

基于 Claude Code + MCP 服务的数据分析项目，无需写代码，直接用自然语言向 Claude 提问即可查询数据。

## 快速接入

### 1. 克隆项目

```bash
git clone <repo-url>
cd us_product_analysis
```

### 2. 用 Claude Code 打开项目

```bash
cd us_product_analysis
claude
```

Claude 会自动加载项目规则（`CLAUDE.md`）和 MCP 服务，即可开始提问。

### 3. 命令行兜底查询样例

当主会话里没有直接暴露 `mcp__mcp-service__executeQuery` 工具时，可使用下面这个已验证可用的 Claude CLI 兜底方式：

```bash
printf '%s' '请使用 mcp__mcp-service__executeQuery 执行 SQL：SELECT 1 AS test_value' \
| claude -p \
  --mcp-config .mcp.json \
  --allowedTools "mcp__mcp-service__executeQuery"
```

预期返回示例：

```text
[{"test_value":1}]
```

说明：
- 当前本机 `claude mcp` 仅支持 `add/list/get/remove/serve` 等管理命令，不能直接用 `claude mcp call`
- 因此需要通过 `claude -p` 启动一个带 MCP 配置的子会话，并通过 `stdin` 传入 prompt
- 请先在项目根目录执行该命令，确保 `.mcp.json` 可被正确加载
- 正式查询时，将上面示例里的提示词替换为“请使用 `mcp__mcp-service__executeQuery` 执行 SQL：<你的SQL>`”即可

---

## 可用 Skill（斜杠命令）

| 命令 | 用途 |
|:---|:---|
| `/data-query` | 通用数据查询规范，适合临时查询 |
| `/platform-weekly` | 各端（platform）周度 GMV / Session / CVR 分析 |
| `/operation-analysis` | 运营位 CTR / 漏斗 / GMV 贡献分析 |


### 使用示例

```
/platform-weekly 查看美国最近一周的 GMV session 数据

/operation-analysis 分析首页 Banner 上周的 CTR 和漏斗转化

查一下 usa 站最近7天 iOS 的 CVR 趋势
```

---

## 数据表说明

| 表名 | 适用场景 |
|:---|:---|
| `bi_warehouse_dw_us_product_daily` | 各端整体 GMV / Session / CVR，详见 `bi_table_readme.md` |
| `bi_warehouse_dw_us_operation_daily` | 运营位 CTR / 漏斗 / GMV 贡献，详见 `bi_operation_table_readme.md` |
| `bi_warehouse_dw_us_list_id_daily` | 运营位行为数据（按 list_id 聚合） |
| `bi_warehouse_dw_spu_platform_daily` | SPU 各端 GMV / 订单 |

### 常用 site 枚举值

| site | 含义 |
|:---|:---|
| `usa` | 美国 |
| `uk` | 英国 |
| `eu` | 欧盟 |
| `au` | 澳大利亚 |
| `de` / `fr` / `es` / `ja` | 德法西日 |

---

## 安全机制

项目内置 Hook（`.claude/hooks/check-mcp-only.sh`），会拦截任何试图直连数据库的操作（psycopg2、psql、postgres:// 等），确保所有查询均通过 MCP 服务执行。

---

## 项目文件说明

```
us_product_analysis/
├── CLAUDE.md                        # 项目规则（Claude 自动加载）
├── README.md                        # 本文件
├── bi_table_readme.md               # bi_warehouse_dw_us_product_daily 字段说明
├── bi_operation_table_readme.md     # bi_warehouse_dw_us_operation_daily 字段说明
├── .mcp.json                        # MCP 服务配置（含共用 token）
└── .claude/
    ├── settings.json                # 项目公共配置（hook 注册、权限）
    ├── settings.local.json          # ❌ 个人配置，不入库
    ├── commands/
    │   ├── data-query.md            # /data-query skill
    │   ├── platform-weekly.md       # /platform-weekly skill
    │   └── operation-analysis.md   # /operation-analysis skill
    └── hooks/
        └── check-mcp-only.sh        # 禁止直连数据库的安全 hook
```
