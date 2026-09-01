# STMini组件

Current Version: V1.0.0

## 规范入口与接入边界

本 README 仅保留 iOS STMini 的实现落点与排查提示，不维护跨端小程序规范。

- 新 iOS 宿主接入 STMini 时，先阅读 [`HOST_INTEGRATION.md`](HOST_INTEGRATION.md)。该文档说明容器已提供的能力、`/web` 与 `/mini` 的边界、在线包协议、宿主 Bridge、更新、保活和验收清单。

- 所有小程序的跨端文档入口是 [`qt-minih5/docs`](../../../qt-minih5/docs/README.md)。对齐顺序固定为：桌面端量化插件（业务基准）→ `qt-minih5`（唯一业务源码）→ iOS / Android / PWA（同一宿主契约实现）。通用容器、扫码、二级 Web 和桌面入口以 [`STMINI_PLATFORM.md`](../../../qt-minih5/docs/STMINI_PLATFORM.md) 为准；量化业务、Bridge 与打包分别以该目录中的量化文档为准。
- iOS 的量化 Host Bridge 落点为 `Local/STBusinessModule/classes/MiniH5/STScriptMessageHandler.m`；它只提供授权校验代发、会话、账户上下文与受控本地记录。授权代发仅在 STMini 的 `inWebview` 分支实现，普通 H5 的 `inCrl` 不改动；完整契约见 `QUANT_MINI_ARCHITECTURE.md`。
- STMini 负责通用的小程序容器、扫码下载/校验/打开、胶囊栏、转场和本地包生命周期；不得把量化策略、MCP 调用或收益业务写进容器。
- iOS 不再内置 `asterquant` 量化包。量化包由 STMini 的通用在线 ZIP 下载、校验和本地安装流程管理；不要在 `SupportFiles/LocalMini` 添加量化业务副本。

“添加到桌面”通用能力的暂停状态和恢复前置条件已收敛至 [`STMINI_PLATFORM.md`](../../../qt-minih5/docs/STMINI_PLATFORM.md)。
