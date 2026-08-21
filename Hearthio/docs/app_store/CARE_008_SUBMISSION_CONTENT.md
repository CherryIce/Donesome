# CARE-008 App Store 提交内容草案

> 状态：仓库内审阅稿，尚未上传 App Store Connect。  
> 对应版本基线：`1.0.0+3`。  
> 使用要求：最终截图必须来自准备提交的同一 TestFlight 构建；正式 Bundle ID、隐私政策 URL、支持 URL 和主体信息到位后再补录，不能使用占位内容提交。

## 1. 产品叙事边界

家务志（Hearthio）是一款本地优先的家庭设备保养生命周期工具。它帮助用户把每件设备的具体保养任务变成可计划、可执行、可留证、可进入下一周期的真实记录。

可以展示的事实：

- 一件物品可建立多个具名保养计划，并从可编辑模板开始。
- 首页、日程和详情使用同一计划日期与状态。
- 用户可按步骤执行保养，记录完成日期、实际费用、耗材、备注及可选照片。
- 完成后保存维护记录并生成下一次计划日期。
- 生命周期时间线只汇总用户填写的购买日期和真实维护记录。
- 报告只汇总真实计划状态、完成记录和记录中的实际费用。
- 核心档案与保养流程不要求账号；除外部隐私政策网页外可离线使用。
- 通知为可选本地提醒；不授权不阻断档案、计划或维护记录。
- CSV/ZIP 仅在用户主动导出、备份或分享时离开 App 沙盒。

禁止使用的表述：

- Apple 官方推荐、官方认证。
- 智能诊断、设备健康分、故障预测、剩余寿命预测。
- 保证延长设备寿命、保证安全或保证节省费用。
- 自动识别设备状态、自动读取厂商或传感器数据。
- 未经最终隐私审计确认的“绝不收集任何数据”。

## 2. App Store 元数据草案（简体中文）

字段限制按当前 Apple 官方说明复核：App 名称和副标题最多 30 个字符，推广文本最多 170 个字符，描述最多 4000 个字符，关键词最多 100 字节。提交时仍需以 App Store Connect 当时显示的校验结果为准。

- [Apple：App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Apple：Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)

### 名称

`家务志`

### 副标题

`家庭设备保养计划与记录`

### 推广文本

`为净水器、空调、洗衣机等家庭设备建立具体保养任务，按步骤完成并留下费用、耗材和照片记录，完成后自动进入下一周期。`

### 关键词

`家庭保养,设备维护,家电保养,保养提醒,维护记录,耗材记录,本地数据`

### 建议分类

- 主分类：工具。
- 次分类：生活。
- 最终分类需在 App Store Connect 中结合目标地区可用分类复核。

### 描述

家务志把家庭设备的保养从一个模糊日期，变成可以真正完成和回看的任务。

你可以为净水器、空调、洗衣机等物品建立多个具名保养计划，从可编辑模板开始，也可以完全自定义周期、提前提醒时间和执行步骤。

当任务到期时，你可以：

- 在首页和日程中查看统一的到期状态；
- 按步骤执行本次保养；
- 记录完成日期、实际费用、耗材型号和备注；
- 按需添加保养前后照片；
- 完成后查看自动生成的下一次计划日期。

每次完成都会进入该物品的生命周期时间线。家庭保养报告只根据真实完成记录和计划状态，汇总本月完成数、当前逾期、未来任务、实际维护费用及有事实依据的按时完成率。

家务志不要求注册账号。物品档案、计划和维护记录默认保存在本机；本地通知可以选择开启，不授权也不影响核心功能。只有在你主动导出 CSV、创建 ZIP 备份或分享文件时，对应内容才会离开 App 沙盒。

## 3. App Review Notes（可直接粘贴草案）

### 中文

本 App 不需要账号或登录，核心保养流程不依赖网络或外部设备。全新安装后可点击引导页右上角“跳过”直接进入首页。

首页已提供一条明确标记且可删除的“示例 · 厨房净水器”，其中“更换滤芯”任务默认今天到期。建议按以下路径检查核心功能：

1. 在首页找到“示例 · 厨房净水器 / 更换滤芯”，点击“开始保养”。
2. 勾选“核对型号、关闭水源、更换、冲洗”四个示例步骤。
3. 在“本次费用”输入 `129`，在“耗材名称 / 型号”输入 `PP 棉滤芯 A1`；照片为可选项，无需授权相机或相册即可继续。
4. 点击“完成本次保养”。结果页会显示本次费用和下一次计划日期。
5. 点击“查看生命周期”，App 会进入该示例物品详情；可以核对累计保养次数、实际费用、下一项任务和刚才生成的时间线记录。
6. 返回首页后点击底部“报告”，可查看只基于真实记录与计划状态生成的保养报告。

如果通知权限尚未开启，完成结果页会如实提示通知未重新安排，但记录和下一次日期已经保存；通知不是完成流程的前提。示例数据可在“设置 → 管理示例数据”删除或重置，重置不会删除用户创建的物品。

### English

No account or sign-in is required. The core maintenance flow works without a network connection or external hardware. On a fresh install, tap “跳过” at the top-right of onboarding to open the Home screen.

A clearly marked and removable sample item, “示例 · 厨房净水器”, is available on Home. Its “更换滤芯” task is due today.

1. Tap “开始保养” on the sample task.
2. Check the four sample steps: model verification, water shutoff, replacement, and flushing.
3. Enter `129` as the actual cost and `PP 棉滤芯 A1` as the material/model. Photos are optional, so Camera or Photos access is not required.
4. Tap “完成本次保养”. The result screen shows the recorded cost and the next scheduled date.
5. Tap “查看生命周期” to open the sample item detail and verify its completion count, actual cost, next task, and new timeline record.
6. Return to Home and open the “报告” tab to view a report derived only from actual records and plan states.

If notification permission is not enabled, the result screen states that the notification was not rescheduled, while the maintenance record and next date remain saved. The sample can be deleted or reset under Settings → Manage Sample Data; resetting it does not remove user-created items.

## 4. 六张截图清单

截图不得伪造未实现的数据、预测或系统通知；标题文案可作为 App Store 截图外层排版，但底层界面必须来自最终 TestFlight 构建。

| 顺序 | 建议标题 | 二进制内页面与准备动作 | 必须可见的事实 |
|---:|---|---|---|
| 1 | 今天该做的保养，一眼看清 | 重置示例数据后进入首页 | 示例净水器、“更换滤芯”、今日到期、开始保养 |
| 2 | 一件设备，可安排多项具体任务 | 打开示例详情或物品编辑页的保养计划区域；需要多计划画面时使用人工创建的真实测试数据 | 计划名称、周期、提前天数、步骤数；模板字段可编辑 |
| 3 | 按步骤执行，记录真实结果 | 从示例任务进入“开始保养”页并填写 `¥129`、`PP 棉滤芯 A1` | 原计划日期、四个步骤、实际费用、耗材与可选照片入口 |
| 4 | 完成本次，自动进入下一周期 | 完成示例任务后停留在结果页 | 完成日期、本次费用、下一次计划、提前提醒天数 |
| 5 | 每次保养，都进入生命周期时间线 | 点击“查看生命周期”进入示例详情并滚动到时间线 | 累计保养次数、实际费用、下一项任务、具名记录与步骤完成情况 |
| 6 | 费用和完成情况，都能从记录复算 | 使用真实测试记录打开“报告”页 | 日期口径、本月完成、逾期、未来 30 天、近 12 月实际费用、按时率说明 |

### 截图验收

- 使用与提交版本一致的最终 TestFlight 构建。
- 每个本地化可上传 1 至 10 张 `.jpeg`、`.jpg` 或 `.png` 截图，文件不得包含 Alpha 通道或透明度。
- 准备一套 Apple 当前接受的 6.9 英寸 iPhone 竖屏尺寸；本 App 支持 iPad，因此同时准备官方要求的 13 英寸 iPad 截图，不能用 iPhone 截图冒充。
- 状态栏时间、语言、金额、日期和示例标记前后一致。
- 不出现 Debug 标记、占位 URL、测试水印、相机/通知权限弹窗或无关系统浮层。
- 截图 3 至 6 使用同一轮真实示例操作，费用、耗材、完成日期和下一日期相互一致。
- 截图 6 的按时率无可复算记录时显示 `—`，不得为了画面填充伪造 `100%`。

具体像素尺寸以提交当天的 [Apple Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) 为准。

## 5. 提交前核对

- [ ] 名称、副标题、描述、关键词与最终二进制一致。
- [ ] Privacy Policy URL 已替换为无需登录即可访问的公开 HTTPS 正式地址。
- [ ] Support URL 已替换为无需登录即可访问的公开 HTTPS 正式页面；页面至少提供一种已核验、可实际联系的支持方式（合法地址、支持邮箱或电话号码），不能只有产品介绍或占位内容。
- [ ] App Privacy 已按最终依赖、网络行为和服务重新审计。
- [ ] 六张截图来自最终 TestFlight 构建并逐项核对。
- [ ] Review Notes 中的按钮名称和导航路径在提交构建上逐步复现。
- [ ] 示例数据可删除、可重置，重置不影响用户数据。
- [ ] 不包含“智能诊断”“延长寿命”等无法证明的结论。
