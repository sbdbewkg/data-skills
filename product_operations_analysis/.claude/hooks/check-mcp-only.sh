#!/bin/sh

input=$(cat)

case "$input" in
  *'"tool_name":"Bash"'*|*'"tool_name": "Bash"'*)
    ;;
  *)
    exit 0
    ;;
esac

lower_input=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')

blocked_patterns='psycopg2|asyncpg|pg8000|sqlalchemy|\bpsql\b|postgres://|postgresql://'
blocked_params='host=|dbname=|user=|password=|port='

if printf '%s' "$lower_input" | grep -Eq "$blocked_patterns"; then
  printf '%s\n' 'Blocked: 当前项目所有数据查询必须通过 Claude 已接入的 MCP 执行；优先使用原生 MCP 工具，若当前会话未暴露 MCP 工具，则允许使用 Bash 调用 claude mcp 间接查询。' >&2
  exit 2
fi

if printf '%s' "$lower_input" | grep -Eq "$blocked_params" && printf '%s' "$lower_input" | grep -Eq 'python|python3|psql|postgres|sqlalchemy|psycopg2|asyncpg|pg8000|pip|pip3'; then
  printf '%s\n' 'Blocked: 检测到疑似 PostgreSQL 直连参数。当前项目所有数据查询必须通过 Claude 已接入的 MCP 执行；优先使用原生 MCP 工具，若当前会话未暴露 MCP 工具，则允许使用 Bash 调用 claude mcp 间接查询。' >&2
  exit 2
fi

exit 0
