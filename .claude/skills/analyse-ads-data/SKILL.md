---
name: ad-analyst
description: 广告数据分析 skill。当用户需要查询广告数据、分析投手业绩、查看广告花费/曝光/点击/ROI 等数据时触发此 skill。适用于用户询问某个投手（林炜、梁嘉晴、谭小艺等）的广告数据，或者查询特定时间范围内的广告表现数据。
---

# 用户语言

在和用户交流的过程中，请全程使用中文

# 广告投手信息

用户查询人的广告时，需要某个通过 adset name 包含该人对应的投手标识来筛选。

| 用户 ID | 用户名 | 投手标识 |
|---------|--------|----------|
| 1249 | 陈芷莹 Jeen | jeen |
| 843 | 梁嘉晴 Summer | summer |
| 1444 | 张珺茹 Emma | emma |
| 1178 | 林炜 | linwei |
| 1922 | 陈米嘉 | mijia |
| 5488 | 黄曼萱 | maxine |
| 5931 | 庄少丽 Shally | shally |
| 5675 | 卢晓迪 | dee |
| 1534 | 李涵 | teddy |
| 4328 | 陈希蕾 | helen |
| 3213 | 高沁怡 | jolene |
| 5398 | 韩美香 | kristina |
| 1446 | 陈玉琳 | yulin |
| 810 | yu | wuyu |
| 6474 | 杨雅乔 | joey |

# 数据库表结构

## bi_warehouse_dw_fb_w2p_country_roi_hourly

- **schema**: public
- **用途**: Facebook 广告及花费信息
- **数据归因窗口期**:  Last Touch
- **查询条件**: 固定添加 `spend > 0`（花费为 0 的数据无价值）
- **时间筛选**: 必须使用 `report_date` 筛选时间，默认最近七天
- **层级关系**: campaign > adset > ad，每个 ad 有唯一的 link_id
- **数据维度**: 这张表的每一行记录，代表某一天内，某一个 ad 在某个国家的相关数据，表的主键为 (link_id, country, report_date)

### 关键字段

| 字段名 | 说明 |
|--------|------|
| account_name | 广告账户名 |
| campaign_name | Facebook campaign name |
| campaign_id | Facebook campaign id |
| adset_name | Facebook adset name |
| adset_id | Facebook adset id |
| ad_name | Facebook ad name |
| ad_id | Facebook ad id |
| report_date | 广告时间，这个字段在使用的时候必须使用 report_date::date 变成 date |
| country | 国家 |
| spend | 花费 |
| impression | 曝光 |
| link_click | 点击 |
| link_id | UUID，广告唯一标识，用于关联不同表的数据 |
| web_new_total_fee | web 端新客 gmv（可能为 null） |
| web_old_total_fee | web 端老客 gmv（可能为 null） |
| web_new_device_id | web 端新客数（可能为 null） |
| web_old_device_id | web 端老客数（可能为 null） |
| app_new_gmv | app 端新客 gmv（可能为 null） |
| app_old_gmv | app 端老客 gmv（可能为 null） |
| app_new_purchase_device | app 端新客数（可能为 null） |
| app_old_purchase_device | app 端老客数（可能为 null） |

### 数据分组

查询时按 `link_id` 和 `country` 做 GROUP BY，因为同一 ad 会有多条记录。

## dws_user_journey_simplification_long

- **schema**: public
- **用途**: 广告 first touch 数据
- **数据归因窗口期**: First Touch
- **查询条件**: 如果用户没有指定归因窗口期，默认使用 `window_period = '7 Days'` 筛选 7 天窗口期的数据
- **时间筛选**: 使用 `time_period_first_touch_event_time` 筛选数据日期，归因窗口期对 time_period_first_touch_event_time 没有影响


### 关键字段

| 字段名 | 说明 |
|--------|------|
| window_period | 归因窗口期，枚举值："7 Days"（7天）、"14 Days"（14天）、"28 Days"（28天），用户提问中的归因窗口期只针对该字段生效 |
| time_period_first_touch_link_id | UUID，广告唯一标识，用于关联不同表的数据 |
| time_period_first_touch_country | 国家 |
| time_period_first_touch_event_time | 广告时间, 这个字段在使用的时候必须使用 time_period_first_touch_event_time::date 变成 date。这个字段与归因窗口期无关，用户如果想要查询 2026 年 1 月 1 号的广告数据，并且归因窗口期为 14 天，那就是 time_period_first_touch_event_time::date = '2026-01-01'，这个字段的查询不需要根据归因窗口期进行调整 |
| time_period_first_touch_campaign_name | 窗口期触达广告 campaign 名字 |
| time_period_first_touch_ads_content | 窗口期触达广告 adset 名字 |
| time_period_first_touch_ad_name | 窗口期触达广告 ad 名字 |
| time_period_touch_count | 窗口期内触点次数 |
| time_period_touch_path | 窗口期触点，格式如 "4.CRM,1.ELSE,5.META,2.自然流量"，多个触点用逗号拼接，前面是触点序号（不重复但不连贯），后面是触点名字 |
| total_fee | 订单 gmv |
| order_id | 订单 id |
| order_new_old_type | 订单新老客属性，"新客" 为新客，其他值为老客 |

# EROI 和 ECAC 系数

获取这两个系数需要查询 bi_warehouse_ods_w2p_coef_fb 这张表，这张表的 schema 是 public 

计算 eroi / ecac 时，需要对 gmv / 花费 进行加权计算，加权计算时需按国家进行加权，每个国家对应的 eroi / ecac 系数查询 sql 如下：

```sql
SELECT country_code,
       max(case when coefficient_type = 'eroi' then value end) as eroi_adjust_coefficient,
       max(case when coefficient_type = 'ecac' then value end) as ecac_adjust_coefficient
FROM bi_warehouse_ods_w2p_coef_fb
where end_date = '20990101'
group by country_code
```



# 查询流程

## 步骤 1: 解析用户需求

1. 识别用户提到的投手姓名
2. 在投手信息表中找到对应的投手标识
3. 确定查询的时间范围（用户未指定时使用最近7天）
4. 确定归因类型（用户未指定时默认 last touch）

## 步骤 2: 数据查询逻辑

1. last touch 相关信息
    1. 使用 `bi_warehouse_dw_fb_w2p_country_roi_hourly` 表
    2. 固定添加 `spend > 0` 条件
    3. 使用 `report_date` 筛选时间
    4. 通过 `adset_name LIKE '%{投手标识}%'` 筛选特定投手的广告
    5. 按 `link_id` 分组
    6. 然后找到对应的 last touch 的相关数据
        1. 广告花费，即对 spend 求和，last touch 的花费和 first touch 是一样的
        2. 曝光，即对 impression 求和
        3. gmv，即对 web 新客 gmv、web 老客 gmv、app 新客 gmv、app 老客 gmv 进行累加求和
        4. roi，通过 gmv 和 花费 来计算
        5. eroi，通过 加权gmv 和 花费 来计算
        6. cac，通过 新客数 和 花费 来计算
        7. ecac 通过 新客数 和 加权花费 来计算
2. first touch 相关信息
    1. 通过 link_id、国家、时间等字段, 到 dws_user_journey_simplification_long 里面通过 time_period_first_touch_link_id、time_period_first_touch_country、time_period_first_touch_event_time 等字段找到对应的数据，link_id / 国家的来源为 last touch 的 link_id、country
    2. 添加对应的窗口期（7/14/28 天）的筛选，比如  `window_period = '7 Days'`，拿到对应窗口期的数据
        1. 如果用户没有指定窗口期，默认使用 7 天窗口期
        2. 如果用户指定了 7/14/28 天窗口期, 使用对应的条件
        3. 如果用户指定的窗口期不在枚举值以内，提示用户窗口期错误，无法继续
    3. 然后找到对应的 first touch 数据：
        1. 订单数，即 order_id 的数量
        2. gmv，对 total_fee 求和
        3. 新客数，order_new_old_type 等于 新客 的 order_id 数量
        4. 老客数，order_new_old_type 不等于 新客 的 order_id 数量
        5. roi，通过 first touch gmv 和 last touch 的花费来计算
        6. eroi，通过 first touch 加权 gmv 和 last touch 的花费来计算
        7. cac，通过 first touch 新客数和 last touch 的花费来计算
        8. ecac，通过 first touch 新客数和 last touch 的加权花费来计算

## 步骤 3: 返回结果

将查询结果以清晰的表格或数据格式返回给用户。

# 时间转换

如果涉及时间，统一需要转换为美西时间处理。

## 获取美西当前时间

使用以下命令获取美西当前日期和时间：

```bash
# 获取美西当前日期和时间（自动处理夏令时）
date -v-8H +"%Y-%m-%d %H:%M:%S"  # macOS
# 或
TZ="America/Los_Angeles" date +"%Y-%m-%d %H:%M:%S"  # Linux

# 获取美西当前日期（格式 YYYYMMDD）
TZ="America/Los_Angeles" date +"%Y%m%d"
```



# 注意事项

1. 需要查询数据库时, 必须直接通过一个大 sql 直接运行得到结果，不允许进行多次 SQL 查询后得到结果
2. 投手标识查询时使用 adset_name LIKE '%标识%' 模式匹配
3. 在得到结论以后
    1. 需要把结论用人类阅读友好的格式提供给用户
    2. 需要把结论中的每项指标来源告诉用户，即得到结论的过程中执行了哪些 sql ，结论中的每个指标是通过什么样的 sql 计算出来的
