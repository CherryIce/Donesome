# STMini：新宿主工程接入指南

本文面向将 `STMini` 接入另一个 iOS 宿主工程的开发者。目标是：**宿主不重写小程序容器，只接入入口、路由和自身业务 API，即可获得在线小程序能力。**

> 适用范围：在线 ZIP 小程序、`mini://` 链接、扫码/CMS Grid 打开、本地安装包、Mini 内二级 Web、包更新与保活。
>
> 本文只定义通用框架与宿主接入边界；量化业务的授权、账户、MCP、收益等规则不是 STMini 的通用能力，应由对应业务模块实现。

## 阅读对象、术语与接入目标

本文的读者是新宿主工程的 iOS 开发、后端配置和小程序开发人员。接入前请统一以下术语：

| 术语 | 定义 | 不能混用为 |
| --- | --- | --- |
| 宿主（Host） | 集成 STMini 的 iOS App，负责自身登录、账户、网络、日志和路由 | 某个小程序或 H5 页面 |
| 小程序（Mini） | 一个 ZIP 安装包，包内含静态 H5、`mini-manifest.json` 和资源 | 普通在线网页 |
| `miniId` | 小程序唯一标识，也是安装目录名和 `mini://` 链接的主机名 | 展示名称、品牌名、包名 |
| 在线包 | 由 `mini://` 加下载地址按需下载并安装的 ZIP | App 编译期内置资源 |
| 本地已安装包 | 经 STMini 校验后位于 `Documents/STMini/<miniId>/` 的包 | 仅存在于临时目录或下载目录的 ZIP |
| 普通 H5 | 以 `http(s)` 打开的网页 | Mini 根页或 Mini 内二级页 |
| Mini 内二级页 | 包内 `mini_navigateTo({ path })` 页面，或 Mini 根页以 `open({ router: "/web", link })` 打开的 HTTPS 页面 | 宿主 `/web` 打开的任意网页 |

一个可交付的宿主接入必须满足以下结果：

1. 后端 Grid 与扫码都能使用同一条 `mini://` 链接打开小程序。
2. 首次打开时，用户只会看到原生加载页、成功页面或明确的失败页，不能出现白屏。
3. 已安装包在没有下载描述的情况下仍能通过 `mini://<miniId>` 再次打开。
4. 宿主能够按自身安全模型向小程序提供 API，但普通 H5 不会意外获得 Mini 或高权限业务能力。
5. ZIP 校验、版本替换和保活恢复均由 STMini 完成，宿主不直接操作安装目录。

## 0. 接入前置条件

在开始编码前，宿主团队必须准备以下内容：

| 类别 | 必需项 | 说明 |
| --- | --- | --- |
| 工程 | 引入 `STMini` 与其资源包 | 确保 Swift、资源 Bundle 和依赖库均加入最终 Target。 |
| 路由 | `/mini` 或等价的 Mini 路由入口 | 接收 `link`，并把 `mini://` 链接交给 `STWebOpenHandler`。 |
| 页面 | 一个可 `present` 的当前控制器 | 在线 Mini 使用全屏 `present`，不能只传导航控制器。 |
| 首页 | 可刷新 Grid/列表的数据源 | 用于在安装完成后展示已安装小程序入口。 |
| Bridge | 宿主 API 分发器 | 至少提供用户语言、Toast/Loading 与业务所需 API。 |
| 发布 | HTTPS 或可访问的 ZIP 下载地址 | 测试环境可用 HTTP；生产环境应使用 HTTPS。 |
| 包 | 符合第 4 节的 ZIP | 不符合结构或清单字段的包不会安装。 |

STMini 不要求宿主一定有扫码页面、首页 Grid 或业务账户系统；这些都是宿主可选入口和业务能力。只要宿主能够调用统一打开方法，任何页面都可以成为 Mini 入口。

## 1. 能力边界

| 能力 | STMini 负责 | 新宿主负责 |
| --- | --- | --- |
| 小程序打开 | 解析 `mini://`、创建 Mini 容器、胶囊栏与转场 | 将自己的路由入口转发到 `STWebOpenHandler` |
| 在线包 | 下载、解压、清单校验、原子安装、版本比较、旧包回退 | 提供下载链接；决定何时展示扫码/Grid 入口 |
| 本地包 | 在 `Documents/STMini/<miniId>/` 加载已校验包 | 不应自行写入或修改该目录 |
| Mini 内页面 | `mini_navigateTo` 创建包内页；Mini 来源的 `open /web` 创建在线二级页，均保留 Mini 身份与导航栈 | 提供普通 H5/业务 JS API 的实际实现 |
| 通用 Mini API | 保活、Mini 内跳转、自有/宿主更新入口、关闭 | 可选实现宿主更新检查回调 |
| 业务 API | 不包含任何账户、登录、交易、量化或品牌规则 | 在 Host Bridge 中按业务实现、鉴权和审计 |
| 首页入口 | 提供已安装包清单变化通知 | 监听通知，刷新自己的首页 Grid/列表 |

因此，接入后任何小程序都可共享同一套容器流程；不同宿主只替换“入口”和“业务数据提供者”。

## 2. 容器与页面模型

```text
宿主路由 / 扫码 / CMS Grid
           |
           +-- https(s)://...  -> 普通 H5（STWebH5Crl）
           |
           +-- mini://<miniId> -> 小程序根页（STWebMiniprogramCrl）
                                  └─ STWebNavigationController
                                     ├─ mini_navigateTo(path) -> 包内本地二级页（STWebH5Crl）
                                     └─ open(/web, link) -> 拦截为 Mini 在线二级页（STWebH5Crl）
```

- **普通 H5**：仅使用宿主已有的普通 H5 API；不是小程序，也不拥有 Mini 包身份、保活或 Mini 专用 API。
- **小程序根页**：`STWebMiniprogramCrl`。在线包会显示原生加载页，直至 ZIP 校验/安装（如需要）和首页 `WKWebView` 完成加载。
- **Mini 内二级页**：仍是 `STWebH5Crl`，但带 `isMiniInternalPage` 标记，因此与根页共享 Mini 身份、导航栈以及允许的 Mini API。`mini_navigateTo` 只接受包内本地相对路径；Mini 发出的 `open /web` 则由 STMini 在进入宿主路由前拦截为在线内部页。

不要把“使用了 `STWebH5Crl`”等同于“小程序页面”：普通宿主 `/web` 是普通 H5；只有从 Mini 根页通过 `mini_navigateTo` 打开的包内页，或 Mini 来源 `open /web` 被容器拦截后打开的在线页，才属于 Mini 内页面。

## 3. 最小接入步骤

### 3.1 引入并初始化 STMini

将 `STMini` 作为 Pod/本地组件引入新宿主工程，确保其资源包随 App 构建。应用启动时只需要配置组件的宿主适配器：

```objc
@import STMini;

- (void)configureSTMini {
    STWebPersonalHandle *handle = [STWebPersonalHandle sharedInstance];
    handle.loadingImg = @"st_web_loading";             // 可选：宿主加载图
    handle.noti_updateUserInfo = @"HostUserChanged";   // 可选：宿主登录态变化通知名

    handle.apiHandle = ^NSDictionary *(NSDictionary *message, STMiniWebView *webView) {
        NSString *method = message[@"method"];
        NSDictionary *params = message[@"params"];
        return [HostScriptMessageHandler handleMiniMethod:method
                                                   params:params
                                                  webView:webView];
    };
}
```

`apiHandle` 是 STMini 调用宿主 API 的唯一通用入口。该 Block 会先于 STMini 内建 API 收到调用，因此宿主只能处理自己拥有的方法；对于框架方法必须明确放行。

| `apiHandle` 返回 | 含义 | 容器后续行为 |
| --- | --- | --- |
| `@{ @"handled": @1, @"code": @"1" / @"0", @"data": ... }` | 宿主已同步处理 | STMini 立即把结果回调给 JS，不再处理该方法 |
| `@{ @"handled": @2 }` | 宿主异步处理 | STMini 不自动回调；宿主必须在完成时使用原始 `methodId` 回调 |
| `@{ @"handled": @0 }` 或不含 `handled` | 宿主不处理 | STMini 继续匹配自身框架 API；若仍不支持则返回失败 |

所有 `data`、`params` 和返回值必须是 JSON 可序列化对象；无参数使用 `{}`，不能用 `nil`、`NSNull` 或包含不可序列化对象的字典。

建议将初始化放在 App 根控制器/应用服务创建后、任何 Mini 打开之前执行一次。重复配置会覆盖上一份 Block，多个业务模块不要分别设置 `apiHandle`；应由一个总分发器统一分派。

一个完整的宿主适配器通常还包括：

```objc
- (void)configureSTMiniHost {
    STWebPersonalHandle *handle = [STWebPersonalHandle sharedInstance];
    handle.loadingImg = @"host_mini_loading"; // 可选，Resource.bundle 中的图片名
    handle.noti_updateUserInfo = @"HostUserStateDidChange";
    handle.darkModeHandle = ^BOOL{
        return [HostThemeManager isDarkMode];
    };
    handle.logHandle = ^(NSString *message) {
        [HostLogger info:message module:@"STMini"];
    };
    handle.apiHandle = ^NSDictionary *(NSDictionary *message, STMiniWebView *webView) {
        return [HostMiniBridge dispatch:message webView:webView];
    };
}
```

`noti_updateUserInfo` 是宿主登录态/用户资料变化的通知名。收到后，STMini 会向运行中的 Mini 下发 `updateUserInfo`；业务 Mini 应重新读取会话，不应继续使用旧账号上下文。

### 3.2 接入统一打开入口

宿主路由层应区分普通 H5 与 Mini：

```objc
// 普通 H5：对应宿主 /web 路由。
[STWebOpenHandler openWebWithUrl:@"https://host.example/path"
                           params:@{ @"from": @"home" }
                              crl:nil
                             navi:self.navigationController];

// 在线小程序：对应宿主 /mini 路由。
[STWebOpenHandler openWebWithUrl:@"mini://examplemini?downloadUrl=https%3A%2F%2Fcdn.example.com%2Fexample.zip"
                           params:nil
                              crl:self
                             navi:nil];
```

ObjC 暴露的方法名以组件头文件为准；Swift 原始签名为：

```swift
STWebOpenHandler.openWeb(
  url: String,
  params: [String: String]?,
  crl: UIViewController?,
  navi: UINavigationController?
)
```

参数要求：

| URL 类型 | 必传控制器 | 打开结果 |
| --- | --- | --- |
| `https://` / `http://` | `navi` | Push 普通 `STWebH5Crl`；`params` 追加到 URL query |
| `mini://<miniId>` | `crl` | Present 全屏 Mini 容器；处理在线包、加载页和保活 |
| `localMini://<miniId>` | `navi` | 打开宿主内置本地 Mini；仅旧有或明确需要的本地包场景使用 |

在线小程序不要使用 `/web` 打开，也不要把 `mini://` 当作普通网页 URL。

### 3.3 建议的宿主路由适配

STMini 不依赖某一个具体路由框架。若宿主已有 `RouterManager`，推荐只在路由层适配一次：

```objc
- (void)openRoute:(NSString *)route params:(NSDictionary<NSString *, NSString *> *)params {
    NSString *link = params[@"link"] ?: @"";
    if ([route isEqualToString:@"/mini"]) {
        if (![link hasPrefix:@"mini://"]) {
            [self showRouteError:@"小程序链接无效"];
            return;
        }
        [STWebOpenHandler openWebWithUrl:link
                                   params:params
                                      crl:[self currentViewController]
                                     navi:nil];
        return;
    }
    if ([route isEqualToString:@"/web"]) {
        [STWebOpenHandler openWebWithUrl:link
                                   params:params
                                      crl:nil
                                     navi:[self currentNavigationController]];
        return;
    }
    [self openExistingNativeRoute:route params:params];
}
```

注意：上例中 `/mini` 与 `/web` 是推荐的**宿主路由名**，不是 STMini 写死的字符串。新工程可以使用其他路由名，但必须保证 `mini://` 进入 Mini 打开流程、`http(s)` 进入普通 H5 流程。

### 3.4 路由参数清理原则

`link` 和 `permission` 是宿主路由层字段。STMini 在真正加载 H5 或 Mini 时会将其从页面 query 中移除，避免把宿主内部路由字段泄漏给页面。

- 需要给网页传递的业务参数：放入 `params` 的其他字段，STMini 会以 URL query 拼接。
- 需要在 Mini 内定位页面：使用 `path`，该值作为 Mini 内 hash 路径处理。
- 不要把登录 token、授权码或账户信息拼到 `mini://` 或 `https://` URL；通过受控 Bridge API 获取。

### 3.5 扫码与 CMS/Grid 统一使用同一链接

二维码和后台 Grid 的 `link` 都使用下列同一协议：

```text
mini://<miniId>?downloadUrl=<zip-url>&currentVersion=<version>&minSupportVersion=<version>&miniName=<name>&miniNameEn=<name>&iconUrl=<image-url>
```

只有 `miniId` 是链接必填项；其他字段均可省略。

完整示例（展示时可换行，实际二维码内容必须是一整行并进行 URL 编码）：

```text
mini://examplemini?downloadUrl=https%3A%2F%2Fcdn.example.com%2Fmini%2Fexamplemini-1.2.0.zip&currentVersion=1.2.0&minSupportVersion=1.1.0&miniName=%E7%A4%BA%E4%BE%8B%E5%B0%8F%E7%A8%8B%E5%BA%8F&miniNameEn=Example%20Mini&iconUrl=https%3A%2F%2Fcdn.example.com%2Fmini%2Fexamplemini.png&path=%2Fhome
```

编码规则：

1. `downloadUrl`、`iconUrl` 本身含 `?`、`&`、`=` 时必须整体 percent-encode，否则会被当作外层 `mini://` 的参数。
2. `miniName`、`miniNameEn` 同样应编码空格、中文及特殊字符。
3. `miniId` 不编码为路径；它只能使用 `[A-Za-z0-9_-]`，并且必须与 ZIP 清单完全相同。
4. 参数键使用 camelCase：`downloadUrl`、`currentVersion`、`minSupportVersion`、`miniName`、`miniNameEn`、`iconUrl`。新发布配置不得继续使用其他拼写。

| 参数 | 含义 | 缺失时行为 |
| --- | --- | --- |
| `miniId` | 唯一包标识，只允许字母、数字、`_`、`-` | 拒绝打开 |
| `downloadUrl` | ZIP 下载地址 | 本地无可用包则无法下载；有本地包可直接打开 |
| `currentVersion` | 服务端期望版本 | 未传时有 `downloadUrl` 则在未命中同版保活实例时优先下载；命中“运行 WebView 版本 = 已验证本地版本”时先恢复运行态并后台验包；无下载地址则打开本地包 |
| `minSupportVersion` | 可立即运行的最低版本 | 本地版本达到该值可先打开，后台静默下载更高版本 |
| `miniName` / `miniNameEn` | 原生加载页名称 | 无链接名称时，优先从已安装包清单读取；仍无则显示 `miniId` |
| `iconUrl` | 原生加载页图标 | 无图标时用已安装包图标；仍无则用宿主加载图 |
| `path` | 小程序内 hash 路径 | 打开安装包后定位到该路径 |

链接参数只用于“打开、展示和下载决策”。安装完成后，包身份、版本、入口、图标、渠道和更新归属始终以**已校验的包内 `mini-manifest.json`** 为准。

### 3.6 链接最小集与常见场景

| 场景 | 建议链接 | 预期行为 |
| --- | --- | --- |
| 第一次扫码安装 | `mini://id?downloadUrl=...&currentVersion=x` | 显示加载页，下载并安装后打开 |
| 首页已安装入口 | `mini://id` | 直接加载已校验本地包，不产生网络请求 |
| 后台配置可弱更新 | `mini://id?downloadUrl=...&currentVersion=x&minSupportVersion=y` | 本地 `>=y` 且 `<x` 时先打开，再静默下载 |
| 后台配置必须更新 | `mini://id?downloadUrl=...&currentVersion=x&minSupportVersion=x` | 本地 `<x` 时必须下载成功后才能打开 |
| 仅重新展示/定位 | `mini://id?path=/settings` | 有可用本地包时直达对应 hash 路径；无包时仍需下载描述 |

不要为“扫码”和“首页点击”定义两种不同 URL 协议。扫码链接可以携带完整下载描述；首页自动入口只保留 `mini://id`，避免每次点击都强制重新下载。

## 4. 包结构与安装规则

### 4.1 ZIP 内容

ZIP 根目录或其唯一一级目录中必须存在：

```text
mini-manifest.json
index.html
assets/...
```

示例：

```json
{
  "miniId": "examplemini",
  "miniName": "示例小程序",
  "miniNameEn": "Example Mini",
  "version": "1.2.0",
  "entry": "index.html",
  "icon": "assets/icon.png",
  "channel": "examplebrand",
  "updateself": "1",
  "ishome": "1"
}
```

字段规则：

| 字段 | 要求 |
| --- | --- |
| `miniId` | 必填，必须等于链接中的 `<miniId>` |
| `version` | 必填，使用点分数字版本比较，例如 `1.2.0` |
| `entry` | 必填，相对安全路径，目标文件必须存在 |
| `icon` | 必填，相对安全路径，目标文件必须存在 |
| `channel` | 必填，业务渠道可由宿主或业务 Bridge 进一步校验 |
| `miniName` / `miniNameEn` | 可选，用于已安装包入口和加载页展示 |
| `updateself` | 可选；`"1"` 小程序自己检查版本，`"0"` 使用宿主统一检查更新；未传按 `"1"` |
| `ishome` | 可选；仅 `"1"` 生效。在线 Mini 仅在下载、校验并安装后读取；App 内置 `localMini` 从其随包 manifest 读取。表示该 Mini 的首层页面替代宿主普通页面：隐藏原生胶囊，并禁用首层侧滑/系统返回关闭；包内二级页仍按正常导航处理。字段缺失或其他值均为普通 Mini。 |

`packageId` 等发布信息可保留在清单中供发布系统使用，但当前 STMini 的安装完整性校验不以它作为身份来源。

### 4.2 安装位置与原子替换

STMini 安装目录：

```text
Documents/STMini/<miniId>/
```

安装过程：下载 ZIP → 临时目录解压 → 校验清单/入口/图标/版本 → 写入安装记录 → 旧包备份 → 原子替换 → 删除备份 → 发布安装完成通知。

宿主不得自行解压、覆盖或删除这个目录。若包校验或替换失败，STMini 会保留旧的已校验包。

版本规则：

- 新包版本高于本地：安装替换。
- 新包版本等于或低于本地：保留本地包；仅更新可用的启动链接记录。
- 强制更新要求新包不得低于已安装版本；低版本下载不会覆盖当前包。
- 需要强制冷启动但下载包版本与本地相同：允许以当前已校验包重新启动，避免运行中的旧 WebView 继续存在。

### 4.3 清单校验的精确规则

STMini 在把 ZIP 变为“已安装包”前，会逐项验证：

1. ZIP 能正常解压。
2. 解压根目录、`<miniId>/` 子目录或唯一一级目录中存在 `index.html`。
3. 找到并能解析 `mini-manifest.json`。
4. `manifest.miniId` 与 `mini://` 链接中的 `miniId` 完全相等。
5. `version` 和 `channel` 非空；`updateself` 若存在只能是 `"0"` 或 `"1"`。
6. `entry`、`icon` 必须是相对安全路径：不能以 `/` 开始，不能包含空路径段、`.` 或 `..`。
7. `entry` 和 `icon` 指向的实际文件必须在包内存在。
8. 上述校验完成后才将候选目录原子替换到 `Documents/STMini/<miniId>/`。

这意味着：下载 HTTP 200 并不代表安装成功；包内 `miniId` 不一致、入口缺失、图标缺失或版本不符合要求都会被视为安装失败。宿主无需、也不应根据 ZIP 文件名推断版本或身份。

### 4.4 版本比较规范

STMini 使用点分数字比较版本，`1.10.0 > 1.2.9`，并忽略 `-` 后的预发布标识进行数字主版本比较。发布方应只使用稳定的 `major.minor.patch` 形式，避免让不同端产生歧义。

| 已安装版本 | 下载包版本 | 普通下载结果 | 强制更新下载结果 |
| --- | --- | --- | --- |
| 无 | `1.2.0` | 安装 `1.2.0` | 安装 `1.2.0` |
| `1.1.0` | `1.2.0` | 替换为 `1.2.0` | 替换为 `1.2.0` |
| `1.2.0` | `1.2.0` | 保留现有包 | 可用现有已校验包冷启动 |
| `1.3.0` | `1.2.0` | 保留 `1.3.0` | 明确失败“强更版本不符”，不覆盖本地包 |

## 5. 在线包打开与更新决策

### 5.1 标准打开流程

```text
收到 mini:// 链接
  ├─ 本地无可用包：下载 → 校验/安装 → 加载首页
  └─ 本地有可用包：
       ├─ 本地版本 >= currentVersion：直接打开本地包
       ├─ 本地版本 < currentVersion 且 >= minSupportVersion：先打开本地包，后台静默下载
       └─ 本地版本 < minSupportVersion：下载、校验/安装成功后再打开
```

若下载失败：

- 有满足最低版本的本地包时，继续打开本地包；
- 无可运行本地包或属于必须更新场景时，不得进入旧包，显示失败并允许按入口策略重试；
- 原生加载页在首页 `WKWebView` 完成首次加载前不能提前消失，避免白屏。

### 5.2 版本字段缺失时的确定行为

| 本地包 | `downloadUrl` | `currentVersion` | `minSupportVersion` | 行为 |
| --- | --- | --- | --- | --- |
| 无 | 无 | 任意 | 任意 | 无法打开，原生失败页提示缺少下载地址 |
| 有 | 无 | 无 | 无 | 直接打开本地已校验包 |
| 有/无 | 有 | 无 | 无 | 未命中同版保活实例时默认优先下载，下载校验后按包内版本决定是否替换；命中时先恢复原运行态并后台验包。下载传输失败时已有本地包可回退 |
| 有，版本 `>= currentVersion` | 有/无 | 有 | 任意 | 直接打开本地包，不下载 |
| 有，`minSupportVersion <= 本地 < currentVersion` | 有 | 有 | 有 | 先打开本地包，后台静默下载；新包下次冷启动生效 |
| 有，`本地 < minSupportVersion` | 有 | 有 | 有 | 阻塞打开，下载并安装成功后才加载首页 |
| 有，`本地 < minSupportVersion` | 无 | 有 | 有 | 无法满足最低版本，显示失败，不可回退至旧包 |

`currentVersion`、`minSupportVersion` 是入口提供的运行策略；包内 `version` 才是安装、替换和最终运行版本的真实来源。

### 5.3 已安装包列表与首页入口

STMini 在成功安装、保留本地包或替换完成后发送：

```objc
[STMiniPackageRegistry installedPackagesDidChangeNotificationName]
```

宿主应监听该通知，并用 `[STMiniPackageRegistry installedPackages]` 重新获取可用包，再刷新首页 Grid。生成的本地入口只需要：

```text
mini://<miniId>
```

推荐监听方式：

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(installedMiniPackagesDidChange:)
                                             name:[STMiniPackageRegistry installedPackagesDidChangeNotificationName]
                                           object:nil];

- (void)installedMiniPackagesDidChange:(NSNotification *)notification {
    NSString *miniId = notification.userInfo[@"miniId"];
    NSString *version = notification.userInfo[@"version"];
    NSArray<STMiniPackageInfo *> *packages = [STMiniPackageRegistry installedPackages];
    [self.homeGrid reloadWithInstalledMiniPackages:packages changedMiniId:miniId version:version];
}
```

通知在主线程发布，说明对应版本已经通过校验并完成原子安装；此时读取包清单和本地入口是安全的。`STMiniPackageInfo` 提供 `miniId`、`miniName`、`iconURL`、`launchLink`，宿主可据此构造图标和文案，但路由仍应使用 `mini://<miniId>`。

不要将二维码的下载地址、版本或图标写回 Grid；这些展示信息已由校验后的清单保存。若后台 Grid 已配置同一 `mini://<miniId>`，宿主应以后台配置为准，避免重复添加。

## 6. JS Bridge 接入

### 6.1 调用与回调格式

Mini 页面调用原生时使用：

```json
{
  "method": "showToast",
  "methodId": "request-unique-id",
  "params": {}
}
```

结果由容器回传：

```json
{
  "method": "showToast",
  "methodId": "request-unique-id",
  "code": "1",
  "data": {}
}
```

- `code: "1"`：成功；`code: "0"`：失败，错误文字放 `data.msg`。
- `methodId` 必须原样回传，否则 H5 无法匹配异步回调。
- `params` 必须是对象；无参数传 `{}`。

建议小程序封装一个唯一 Bridge 调用器，而不要由各页面直接拼消息：

```js
function callHost(method, params = {}) {
  const methodId = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  return new Promise((resolve, reject) => {
    pending.set(methodId, { resolve, reject });
    hostBridge.postMessage({ method, methodId, params }); // 项目现有 Bridge 封装
  });
}
```

具体 JS 注入对象名称由 `STMiniWebView` 的 Bridge 实现决定；小程序工程应复用其现有桥接封装，不要在业务代码中依赖某个宿主私有的 `window` 名称。这里的代码只说明 `method`、`methodId` 和 `params` 的契约。

### 6.2 宿主 Bridge 的职责

`STWebPersonalHandle.apiHandle` 接收 `method`、`params` 和当前 `STMiniWebView`。宿主实现时应：

1. 先识别普通通用 API（语言、Toast、Loading、网络、日志、用户态等）。
2. 再识别本业务 API（例如账户、授权、交易能力）。
3. 对涉及业务权限的 API，依据当前 Mini 根页身份、已校验清单的渠道及宿主登录/账户状态校验。
4. 不处理的方法返回 `handled: 0`，由 STMini 再尝试处理其框架 API。
5. 已处理的方法返回 `handled: 1` 和标准回调结果；确需异步时返回 `handled: 2`，并由宿主自行在完成后使用原 `methodId` 回调。

宿主分发器必须能区分以下三种页面来源：

| 来源 | 可提供的能力建议 | 识别方式 |
| --- | --- | --- |
| 宿主普通 H5 | 普通 H5 API | 普通页面控制器/现有 H5 Handler |
| Mini 根页 | 普通 API + 框架 Mini API + 该 Mini 被授权的业务 API | `STWebMiniprogramCrl.miniProgramId` |
| Mini 内二级页 | 与所属 Mini 根页相同的普通 API、框架 Mini API 和业务权限 | 由 `STWebApiManager.onlineMiniRootController(for:)` 解析根页 |

业务 API 的授权主体永远是“经容器解析出的 Mini 根页”，而不是 H5 自己上传的 `miniId` 参数。这样，二级页能继承根页权限，普通 H5 也无法伪造 Mini 身份。

示意：

```objc
if ([method isEqualToString:@"showToast"]) {
    [HostToast show:params[@"title"]];
    return @{ @"handled": @1, @"code": @"1", @"data": @{} };
}
if ([method isEqualToString:@"hostGetAccount"]) {
    // 校验登录态、当前账户与调用 Mini 的权限后再返回。
    return @{ @"handled": @1, @"code": @"1", @"data": accountPayload };
}
return @{ @"handled": @0 };
```

### 6.3 STMini 已实现的框架 API

这些 API 由 STMini 自己处理，宿主不应重复实现：

| API | 页面范围 | 作用 |
| --- | --- | --- |
| `mini_navigateTo` | 已验证 Mini 根页及其二级页 | Push 当前包内的本地二级页；参数 `{ path, title? }` |
| `mini_getMiniProgramContinuousKeepAlive` | 在线 Mini 根页及其二级页 | 读取当前 Mini 的持续保活开关 |
| `mini_setMiniProgramContinuousKeepAlive` | 在线 Mini 根页及其二级页 | 设置 `{ enabled }`；是否允许由宿主业务/白名单决定 |
| `mini_checkMiniProgramUpdate` | `updateself: "0"` 的在线 Mini | 转发给宿主统一更新检查回调 |
| `mini_downloadMiniProgramUpdate` | `updateself: "1"` 的在线 Mini | STMini 下载、校验并安装自更新包；参数 `{ downloadUrl, isforce }` |
| `close` | 容器页面 | 关闭当前弹出式容器 |

普通 `/web` 页面不拥有以上 Mini API；Mini 内 `mini_navigateTo` 打开的本地二级页，以及 Mini 内 `open({ router: "/web" })` 拦截后打开的在线二级页，都与根页共享同一个 Mini 身份。

### 6.3.1 已安装包的隔离资源源

在线 Mini 的 ZIP 解包并完成校验后，根页和 `mini_navigateTo` 打开的包内二级页必须使用同一个、按 `miniId` 隔离的受控资源源。iOS 采用 `stmini://<miniId>.stmini.local/<path>`，由 `WKURLSchemeHandler` 只读取该 Mini 已校验目录中的常规文件；Android 采用并拦截 `https://<miniId>.stmini.local/<path>`。两端的约束相同：

- 根页与包内二级页共享同一 `miniId` origin，因此可共享该 Mini 自己的 `localStorage` 和相对资源缓存。不要以 Cookie 作为包内状态：iOS 使用自定义 `stmini` scheme，其 Cookie 行为不应作为跨页契约。
- 不同 `miniId` 的 host 必须不同，禁止使用所有小程序共用的 `stmini.local`，避免跨小程序读写存储。
- 资源读取不能把整个文件一次性读入内存：iOS 以 64KB 分块、最多 4 路并发回调 WebKit；Android 由 WebView 资源拦截器直接流式读取文件。两端都按 `miniId + packageVersion` 缓存已验证结果，包原子替换前后必须使缓存失效。
- 资源解析只能接受当前已校验包内的相对路径；协议、绝对路径、`.` / `..`、目录及跨 `miniId` host 一律拒绝。
- iOS 不可用 `WKURLSchemeHandler` 接管 `http` 或 `https`，所以使用专用 `stmini` scheme；这不是外网请求，也不授予文件系统读取权限。

### 6.4 关键 API 的参数与时序

#### `mini_navigateTo`

```json
{ "path": "pages/strategy-detail.html?id=grid", "title": "策略详情" }
```

- 只接受当前已校验包内的相对文件路径；禁止协议、绝对路径与 `..` 逃逸。
- `title` 可选；缺失时由页面标题/宿主导航配置决定。
- 它只是在现有 Mini 导航栈内 Push 二级页面，不下载、不安装、不切换 Mini 包。
- 返回当前 Mini 时，根页 WebView 不会重建，运行中 JavaScript 状态仍在。

在线说明、帮助等页面使用已有的普通 `open` API。H5 应按自身已有的域名白名单策略传入 `isNeedNavigationBar`：当前站点、`H5_BASE_HOST`、`API_BASE_HOST` 使用 `"false"` 隐藏原生导航栏；其他受允许 HTTPS 域名使用 `"true"` 显示原生返回栏。

```json
{ "router": "/web", "link": "https://docs.example.com/guide", "title": "使用说明", "isNeedNavigationBar": "true" }
```

当调用者属于 Mini 导航栈时，STMini 必须在宿主普通 `/web` 路由前拦截该调用，以同一 Mini 栈 Push 在线二级页；只在此拦截分支读取 `isNeedNavigationBar`。值为 `"1"`、`"true"` 或 `"yes"` 时显示原生返回栏，其他值隐藏；字段缺失也默认隐藏。普通 H5 调用相同 `open /web` 则维持原有宿主路由行为，不读取或改变该参数。

#### `mini_setMiniProgramContinuousKeepAlive`

```json
{ "enabled": true }
```

- 仅在线 Mini 根页或其二级页可用；普通 `/web` 页面不具备该能力。
- 容器按 `miniId` 保存设置；设置本身可跨 App 冷启动保留，但实际 WebView 只可能存活于当前 App 进程。
- 业务需要白名单时，宿主应在 `apiHandle` 中拦截未授权 Mini；不要仅依赖 H5 隐藏设置开关。

#### `mini_downloadMiniProgramUpdate`

```json
{ "downloadUrl": "https://cdn.example.com/examplemini-1.2.0.zip", "isforce": 1 }
```

- 仅适用于包内 `updateself: "1"` 的在线 Mini。
- `downloadUrl` 必填；`isforce` 必填，支持布尔值、数字或字符串 `1/0`。
- `isforce=1`：容器立即关闭当前运行时、跳过保活复用、展示原生加载页，校验安装成功后冷启动新包。失败不回到旧运行中的页面。
- `isforce=0`：当前页面继续运行，容器在后台下载、校验、替换；下次冷启动才使用新包。

#### `mini_checkMiniProgramUpdate`

- 仅适用于包内 `updateself: "0"` 的在线 Mini。
- 它只负责把检查请求交给 `miniProgramUpdateCheckHandle`；具体版本服务、升级文案与业务策略由宿主定义。
- 无论 H5 传什么，STMini 都以已校验包清单覆盖请求中的 `miniId` 与 `updateself`。

### 6.5 宿主统一更新（可选）

当包内 `updateself` 为 `"0"` 时，`mini_checkMiniProgramUpdate` 会调用：

```swift
STWebPersonalHandle.sharedInstance().miniProgramUpdateCheckHandle
```

STMini 会覆盖 H5 传入的 `miniId` 和 `updateself`，以已校验清单为准。宿主可在回调中调用自己的统一版本服务；下载、校验、安装仍由 STMini 管理。未接入时，API 明确返回“宿主检查更新尚未接入”，不会静默伪成功。

## 7. 保活与生命周期

STMini 默认可缓存有限数量的已打开 Mini 导航容器，以便再次打开时恢复运行状态。持续保活是单个 Mini 的特殊开关，用于业务确实需要在 App 运行期间尽量保持 WebView 的场景。

- 默认缓存是 **2 个**已关闭的在线 Mini 根导航栈，按 **FIFO（先进先出）** 淘汰；缓存的是整个 Mini 导航栈，因此 Mini 内二级页也可恢复。
- 普通保活与持续保活使用完全相同的不可见、非交互运行容器，因此两者都尽量保持 WebView 的 JavaScript、Bridge 订阅和页面状态继续运行，避免 `WKWebView` 脱离窗口后暂停定时器。唯一差异是：持续保活条目不占用普通 FIFO 的 2 个名额，也不因随后进入普通 Mini 而被普通 FIFO 淘汰。两者都不能保证系统不会因内存压力杀掉网页进程；收到 iOS 内存警告时，STMini 会主动释放全部隐藏普通/持续保活实例，保留包与用户持续保活偏好，下一次打开冷启动已校验本地包。该次冷启动文档加载完成后，宿主必须仅提示一次“小程序后台运行实例已因内存压力释放，已重新加载”，不能误报为 Web 内容进程被系统终止。保活不是提高并发额度的机制：高频 Mini 必须在隐藏态降低网络和渲染并发，不能把定时器、快照写入或 DOM 重建塞到宿主主线程。
- 当前组件内置量化 Mini 白名单：`asterquant`、`ruixianquant`、`nexusalpha`。它们默认开启持续保活，但用户可显式关闭；关闭后写入 opt-out 设置，不能在下次打开时被强行重新打开。
- 持续保活仅对白名单 Mini 开放。非白名单 Mini 调用 `mini_getMiniProgramContinuousKeepAlive` 或 `mini_setMiniProgramContinuousKeepAlive` 会收到 `supported: false`，不会创建独立常驻 WebView；它们仍可使用受 2 个 FIFO 名额限制的普通保活。
- 保活不保证 iOS 不会回收 `WKWebView` 进程。若系统终止网页进程，STMini 会丢弃失效缓存、冷启动本地包，并通过宿主 `showToast` 提示恢复结果。
- 持续保活只覆盖 **App 保持前台活跃、Mini 被关闭或切到宿主其他页面** 的情形；用户将整个 App 置于 iOS 系统后台后，系统仍可冻结 WebView/JavaScript，STMini 不承诺交易策略继续运行。
- 强制更新会主动关闭当前 Mini、跳过保活复用、清空旧运行时，然后用原生加载页冷启动更新后的包。
- 登录、账户、语言等宿主状态变化应通过通知或宿主 API 让业务 Mini 刷新/失效会话；STMini 本身不理解业务账户语义。

### 7.1 保活可复用的前提

一个 Mini 只有同时满足以下条件才会从缓存恢复：

1. 它是在线 Mini 根页，不是独立普通 H5 或本地 `localMini://` 页面。
2. 首屏文档已经完成加载。
3. `WKWebView` 内容进程尚未终止。
4. 缓存时记录的包版本仍等于磁盘中已校验包版本。
5. 新打开链接没有要求一个高于本地且不满足最低支持版本的更新。

任一条件不满足，STMini 会丢弃缓存并冷启动；这不是错误，而是防止复用旧网页进程导致白屏、旧版本页面或错误账户会话。

### 7.2 宿主状态事件

宿主应在相应状态变化后发出通知或直接通过自身 Bridge 让 Mini 刷新。当前 STMini 会监听/下发的事件语义为：

| 事件 | STMini 对 Mini 的通知 | 宿主应在何时触发 |
| --- | --- | --- |
| 用户资料或登录态变化 | `updateUserInfo`、`hostQuantSessionChanged` | 登录成功、退出登录、用户资料刷新 |
| 当前交易账户变化 | `hostQuantSessionChanged` | 切换交易账户、账户类型变化、账号失效 |
| 宿主语言变化 | `hostLocaleChanged`，携带 `locale` | App 切换语言后 |
| 深浅色外观变化 | `darkModeChanged` | iOS trait 发生变化 |
| 宿主进入后台 | `appHide` | 当前正在显示的**首层 Mini**在宿主将失活时立即接收；保活池中隐藏的 Mini 不接收 |
| 宿主回到前台 | `appShow` | 当前正在显示的**首层 Mini**在宿主重新活跃后接收；其二级页在前台时仍由所属首层 Mini 接收 |
| Mini 运行容器可见性变化 | `hostMiniRuntimeVisibilityChanged`，携带 `{ hidden: Boolean }` | Mini 进入不可见保活容器、重新 present，或宿主切换使其可见性变化后 |
| 页面重新可见 | `pageWillAppear` | 容器重新显示、保活恢复 |

量化等高状态业务应把 `hostQuantSessionChanged` 视为失效边界：停止依赖旧账户的后台工作，重新请求宿主会话后才能继续运行。收到 `appHide` 后暂停非必要轮询、动画和媒体并落盘待写状态，但不必主动断开 Socket；收到 `appShow` 后确认连接并刷新可能过期的登录态、账户等数据。浏览器 `visibilitychange` 只可作为 PWA 无原生 Bridge 时的兜底，不能覆盖 iOS/Android 的 `appShow` / `appHide`。收到 `hostMiniRuntimeVisibilityChanged({ hidden: true })` 后可继续业务 worker，但不得重建可见 DOM；收到 `{ hidden: false }` 后合并刷新可见状态。App 回前台后宿主可探测 Web 内容进程是否仍存活，但 `document.readyState` 的失败或超时只代表 WebKit 可能仍在恢复，必须做延迟复查，不能自行判定内容进程已经终止、更不能因此展示“进程已终止”提示。只有收到 WebKit 的真实终止回调时，STMini 才丢弃失效缓存并冷启动恢复。STMini 只负责通知与容器恢复，不会自行理解或停止业务策略。

## 8. 网络请求边界

不要把“小程序的网络请求”一概认为由同一方发出。应按请求类型区分：

| 请求类型 | 发起方 | 是否经过宿主网络库 | 说明 |
| --- | --- | --- | --- |
| 小程序 ZIP 下载、安装、校验 | STMini | 否 | STMini 使用自身 `URLSession` 下载归档，并完成解压、清单校验和原子安装；宿主只提供 `downloadUrl`。 |
| H5 自行 `fetch` / XHR / 资源加载 | `WKWebView` | 否 | 网页进程直接请求网络，不经过宿主网络拦截或宿主登录态注入。 |
| H5 调用 `requestNetwork` | 宿主 Bridge | 是 | 由宿主的网络库发出；适合需要宿主域名、会话、统一超时、风控或请求日志的业务接口。 |
| H5 调用 `logNetworkRequest` | 宿主日志系统 | 不发请求 | 仅记录业务请求摘要，日志规则应与宿主网络日志保持一致。 |

量化小程序当前的授权、检查更新、更新通知等关键业务接口统一调用通用 `requestNetwork`，由宿主代发；同时通过 `logNetworkRequest` 写入宿主日志。其他新小程序可自行选择直接 `fetch` 或宿主代发，但涉及登录态、账户、权限或统一审计的接口应优先走 `requestNetwork`。

宿主实现 `requestNetwork` 时必须明确约束：

1. 接收 `method`、`path`、`params`、`headers` 与可选 `domain`；`domain` 缺失时使用宿主默认业务域名，传入时才使用指定域名。
2. 不自动把登录 `Authorization`、Cookie、真实设备标识注入第三方 `domain`；敏感请求头只应由受信任的宿主域名策略注入。
3. Bridge 和日志中均不得记录 token、授权码、真实设备标识及带敏感 query 的完整 URL。
4. 返回值保持统一 Bridge 契约：成功 `code: "1"`，失败 `code: "0"`，错误消息放入 `data.msg`。

建议请求格式：

```json
{
  "method": "POST",
  "path": "/api/example/query",
  "params": { "page": 1 },
  "headers": { "X-Request-Source": "mini" },
  "domain": "https://api.example.com"
}
```

| 字段 | 类型 | 必填 | 宿主处理 |
| --- | --- | --- | --- |
| `method` | String | 是 | 支持的 HTTP 方法由宿主白名单决定；建议标准化为大写。 |
| `path` | String | 是 | 相对路径时与默认/传入域名拼接；不得允许 `..` 或非 HTTP(S) scheme。 |
| `params` | Object | 否 | 缺失、`null` 或非对象可按 `{}` 降级；GET 通常编码为 query，其他方法通常为 JSON body，由宿主统一规定。 |
| `headers` | Object | 否 | 只允许字符串键值；宿主对受保护域名可追加必要头，对外部域名不得自动附加敏感头。 |
| `domain` | String | 否 | 未传时使用宿主默认业务域名；传入时必须经过宿主域名白名单或显式风险策略。 |

建议响应格式：

```json
{
  "code": "1",
  "data": {
    "statusCode": 200,
    "headers": { "content-type": "application/json" },
    "body": { "ok": true }
  }
}
```

失败示例：

```json
{
  "code": "0",
  "data": { "msg": "网络请求超时", "statusCode": 0 }
}
```

`logNetworkRequest` 应记录经脱敏后的 method、域名、path、状态码、耗时、请求 ID 与错误类型；不得把完整授权头、Cookie、token、授权码或账户信息写入 JS Bridge 日志、原生日志或分析平台。

## 9. 路由、扫码和首页接入示例

建议宿主仅暴露两个统一入口：

```text
/web   -> link 为 https(s) 普通网页
/mini  -> link 为 mini:// 小程序协议
```

扫码：扫描结果为 `mini://` 时，直接交给 `/mini`；其他网页按现有规则交给 `/web` 或普通业务路由。

首页 Grid：后端配置项直接把同一 `mini://` 放在 `link` 中；本地自动生成项则只放 `mini://<miniId>`。用户点击时两者都走 `/mini`，不应另写一套扫码下载逻辑。

## 10. 安全与故障处理要求

1. 不信任 H5 传入的包版本、Mini ID、渠道或更新归属；涉及包身份的判断必须读取已校验清单。
2. 不让普通 `/web` 获得 Mini API 或业务高权限 API。
3. 业务 API 必须同时校验调用 Mini、宿主登录态、账号状态和渠道/品牌（如业务需要），而不是只看 H5 参数。
4. 不在日志中记录 token、授权码、真实设备标识、账户敏感字段或完整带敏感 query 的 URL。
5. ZIP 下载、解压和安装失败时保持当前已校验包；不要删除旧包后再尝试安装新包。
6. 首页入口只从 `[STMiniPackageRegistry installedPackages]` 的可用结果生成；目录存在不代表包可用。

### 10.1 原生失败页与重试

在线包首次打开、阻塞升级或强制自更新失败时，STMini 保持原生加载层并展示“关闭 / 重试”失败页。宿主不应额外盖一层同类 Loading 或提前 dismiss 容器。

| 失败类别 | 典型原因 | 是否自动重试 | 是否可以打开本地包 |
| --- | --- | --- | --- |
| 传输失败 | 超时、离线、HTTP 非 2xx、局域网首次连接未就绪 | 下载步骤自动重试 1 次 | 仅普通首次下载且已有可用本地包时可回退 |
| ZIP 临时文件失败 | 下载文件无法复制、空间/文件系统异常 | 下载步骤自动重试 1 次 | 按同上 |
| 包校验失败 | 清单/入口/图标/miniId/路径不合法 | 不自动重试 | 不自动回退；避免把损坏包当作可用更新 |
| 安装替换失败 | 原子移动失败、磁盘写入失败 | 不自动重试 | 旧包仍在；由入口策略决定是否重新打开 |
| 强更低版本 | 下载包版本低于已安装版本 | 不自动重试 | 不允许使用该下载包覆盖；提示“强更版本不符” |

“重试”应重新执行原链接的打开/下载流程，而不是复用失败 ZIP 或临时解压目录。

### 10.2 诊断日志

STMini 通过 `STProjectHelper.Log` 记录关键生命周期。宿主应将 `STWebPersonalHandle.logHandle` 接入自己的日志系统，并保留以下字段用于定位问题：

```text
miniId、安装前后版本、入口类型（扫码/Grid/本地）、下载 URL 的脱敏域名和 path、
HTTP 状态、下载尝试次数、ZIP 字节数、校验/安装结果、是否命中保活、保活恢复耗时、Web 内容进程是否终止；量化审计环或量化快照写入超过 16ms 时，记录耗时、字节数/字段数和成功状态，但不得记录快照正文、token 或授权信息。量化审计 JSON 校验与 `NSUserDefaults` 写入必须和快照共用串行后台队列，回主线程只允许发送 Bridge 回调。异步量化快照请求在入队前必须固定账户作用域 storage key；写入成功后的 bootstrap 回调也必须从该**同一 key**读取，不能在回调时按已经切换的当前账户重新计算 key。bootstrap 组装与 JSON 文本序列化同样属于后台数据工作，主线程仅执行 `evaluateJavaScript`；其日志只记录 `method`、成功状态和回调字节数，禁止在主线程调用会遍历完整 bootstrap 的通用结果日志。
```

日志中只能记录 URL 的安全摘要。例如 `https://cdn.example.com/mini/example.zip` 可以记录；带 token、签名或账户参数的 query 必须删除或掩码后再记录。

常见排查路径：

| 现象 | 首先检查 |
| --- | --- |
| 扫码后白屏 | 是否直到 `webviewDidFinish` 才移除加载页；是否包入口存在；Web 内容进程是否被终止 |
| 下载成功但安装失败 | `mini-manifest.json` 的 `miniId`、`entry`、`icon`、`channel` 与文件路径 |
| 扫码后仍显示旧版本 | 下载包内实际 `version` 是否更高；是否命中弱更新（新包下次冷启动才生效）；是否复用了旧保活实例 |
| 首页没有新入口 | 是否收到安装完成通知；宿主是否监听通知后重取 `[STMiniPackageRegistry installedPackages]`；是否被后端同 ID Grid 配置覆盖 |
| 再次打开白屏 | 缓存 Web 内容进程是否已被系统终止；应冷启动而非强行复用 |
| Mini API 不支持 | 页面是否普通 `/web`；保活/更新 API 是否属于在线 Mini 根页/二级页；宿主是否错误地截获了框架 API |

## 11. 新宿主验收清单

- [ ] `https(s)` 和 `mini://` 分别被送往 `/web`、`/mini`。
- [ ] 首次扫码：下载、校验、安装、原生加载页、首页打开正常。
- [ ] 再次打开：使用本地包；已下载包不会重复下载。
- [ ] 更高版本：按 `currentVersion`/`minSupportVersion` 走前台或后台更新。
- [ ] 下载/安装失败：有合格本地包时可回退；强制更新不进入不满足最低版本的旧包。
- [ ] 安装完成通知可刷新首页入口，且不会与后台配置项重复。
- [ ] `mini_navigateTo` 可打开并返回二级页；普通 `/web` 无 Mini 权限。
- [ ] 宿主 API 的成功、失败、异步回调均带正确 `methodId`。
- [ ] 包下载、H5 直连和宿主 `requestNetwork` 三种网络路径的日志与敏感头策略均符合上表。
- [ ] 持续保活、系统回收和强更冷启动均无白屏、无旧 WebView 复用。
- [ ] 真机确认 `Documents/STMini/<miniId>/` 只有通过清单校验的包。

### 11.1 建议验收用例

| 编号 | 操作 | 预期结果 |
| --- | --- | --- |
| M01 | 清空 `Documents/STMini`，扫码完整 `mini://` | 原生加载页 → 下载 → 安装 → 首屏；首页出现入口 |
| M02 | 点击自动生成的 `mini://id` 首页入口 | 不下载，直接打开已安装包 |
| M03 | 本地为 `1.0.0`，链接要求 `current=1.1.0,min=1.0.0` | 先打开 `1.0.0`，后台下载；下次冷启动为 `1.1.0` |
| M04 | 本地为 `1.0.0`，链接要求 `current=1.1.0,min=1.1.0` | 不进入旧页面；下载安装后才打开 |
| M05 | 下载包 `miniId` 与链接不一致 | 安装失败，旧包不被覆盖 |
| M06 | 已安装 `1.1.0`，强更返回 ZIP `1.0.9` | 显示强更版本不符，本地 `1.1.0` 仍完整 |
| M07 | Mini 打开二级 HTTPS 页面再返回 | 回到根页，根页 JS 状态未重置 |
| M08 | 普通 `/web` 页面尝试调用 `mini_navigateTo` | 被拒绝，不获得 Mini 身份 |
| M09 | 关闭并再次打开保活 Mini | 首屏不重载；若系统已终止网页进程则冷启动并提示恢复 |
| M10 | 安装完成后不下拉刷新首页 | 首页通过通知自动出现入口；后端同 ID 配置不重复添加 |

## 12. 代码定位

| 需求 | STMini 代码 |
| --- | --- |
| 统一打开、链接参数 | `classes/frame/WebView/Open/STWebOpenHandler.swift` |
| 下载、清单校验、安装、已安装列表 | `classes/frame/STWebResourceManager.swift` |
| Mini 根页、加载页、更新、保活、进程恢复 | `classes/frame/WebView/WebCrl/Miniprogram/STWebMiniprogramCrl.swift` |
| JS API 分发、Mini 二级页、框架 API | `classes/frame/WebView/Api/STWebApiManager.swift`、`STWebRouterApi.swift` |
| 宿主适配器 | `classes/frame/WebView/PersonalHandle/STWebPersonalHandle.swift` |
| Mini 导航容器 | `classes/frame/WebView/Navi/STWebNavigationController.swift` |

量化小程序的策略、收益、MCP、授权及渠道规则请继续参考 [`qt-minih5/docs`](../../../qt-minih5/docs/README.md)；不要将这些业务代码合入 STMini。
