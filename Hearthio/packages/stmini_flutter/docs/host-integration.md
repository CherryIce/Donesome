# STMini Flutter 宿主接入文档

`stmini_flutter` 是 iOS Flutter 宿主使用的通用 Mini 容器。它负责下载、
校验、安装和打开 Mini ZIP，并提供通用 JS Bridge 与生命周期事件。

组件不保存任何品牌信息、App 包名、Mini ID、下载地址、业务域名、账号或交易
逻辑。它们全部属于宿主工程。

## 1. 职责边界

| 位置 | 负责内容 |
| --- | --- |
| `stmini_flutter` | `mini://` 解析、ZIP 下载与校验、原子安装、已安装包复用、Mini/Web 容器、通用 Bridge、隐私清单与事件流 |
| 宿主 Flutter App | App 包名、Mini 下载链接和版本、启动时机、宿主启动页、可选业务会话配置 |
| Mini H5 | 页面路由、业务 UI、登录/退出、调用 JS Bridge、Mini ZIP 内容 |

宿主切换品牌时，通常只需要替换 `packageName` 和 `mini://` 链接；不要修改
组件源码，也不要将业务标识写入组件。

## 2. 添加依赖

开发时可使用本地组件目录：

```yaml
dependencies:
  stmini_flutter:
    path: ../../ST/stmini_flutter
```

发布后使用 Git 仓库：

```yaml
dependencies:
  stmini_flutter:
    git:
      url: https://github.com/fsst-ios/stmini_flutter.git
      ref: main # 建议发布后改为确定的 tag 或 commit
```

执行：

```bash
flutter pub get
```

iOS 最低部署版本为 13。组件会由 Flutter 自动注册；无需在宿主工程复制
`ios/STMini` 的源码或添加绝对路径。

## 3. 宿主启动并打开 Mini

在 Flutter 首帧之后调用，保证 iOS 有可用于 present 的控制器：

```dart
import 'package:flutter/widgets.dart';
import 'package:stmini_flutter/stmini_flutter.dart';

const homeMiniLink =
    'mini://examplemini?'
    'downloadUrl=https%3A%2F%2Fcdn.example.com%2Fexamplemini-1.0.0.zip&'
    'currentVersion=1.0.0&'
    'minSupportVersion=1.0.0&'
    'miniName=Example%20Mini&'
    'miniNameEn=Example';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HostApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await StminiFlutter.initialize(
      bridgeContext: const {
        // 可选。H5 调用 getPackageName 时返回宿主 App 自己的包名。
        'packageName': 'com.example.host',
      },
    );
    await StminiFlutter.openMini(homeMiniLink);
  });
}
```

`initialize` 可以多次调用，但应在每次 `openMini` 前至少成功调用一次。
`packageName` 没有默认值；若不传，H5 的 `getPackageName` 返回空字符串。

## 4. `mini://` 链接契约

基本格式：

```text
mini://<miniId>?downloadUrl=<URL 编码后的 ZIP 地址>&currentVersion=<版本>&minSupportVersion=<版本>
```

| 参数 | 是否必填 | 说明 |
| --- | --- | --- |
| `miniId` | 是 | Mini 唯一标识；用于本地安装目录和包隔离 |
| `downloadUrl` | 首次安装时建议提供 | ZIP 下载地址，必须 URL 编码 |
| `currentVersion` | 建议提供 | 服务端当前版本；高于本地版本时下载新包 |
| `minSupportVersion` | 建议提供 | 最低可运行版本；本地低于该版本时强制更新 |
| `miniName` / `miniNameEn` | 否 | 本地列表和加载界面的展示名称 |
| `iconUrl` | 否 | Mini 图标地址 |
| `path` | 否 | 打开后的 Mini 内路由 |

ZIP 内必须包含有效的 `mini-manifest.json`，版本要与宿主链接中的版本策略一致。
如果提高了 `minSupportVersion`，设备会放弃过旧本地包并下载新包。

## 5. H5 Bridge

组件提供通用 UI、存储、路由、日志和生命周期能力。Mini H5 应通过既有
`jsBridge.call(method, params)` 调用，而不是依赖任何宿主 App 的原生类。

常用通用能力包括：

- `open`：Mini 内 `/web` 路由由原生二级 WebView 打开；其他路由按 Mini/H5
  自身规则处理。
- `close`、`showToast`、`showLoading`、`hideLoading`。
- `getPackageName`：返回宿主在 `bridgeContext.packageName` 中传入的值。
- `getStorage`、`setStorage`、`removeStorage`：Mini 隔离的本地存储。
- `getLanguage`、`logNetworkRequest` 与生命周期回调。

组件不会内置用户 Token、用户资料、业务域名或登录跳转规则。若某个宿主需要
和在线 `/web` 页面同步会话，必须显式通过 `bridgeContext` 配置，并严格限制
允许的存储键和域名；不要将完整业务缓存或敏感数据无差别注入 WebView。

## 6. 直接由宿主打开外部网页

不需要 Mini ZIP 的外链可以直接调用：

```dart
await StminiFlutter.openWeb(
  'https://example.com/help',
  title: '帮助中心',
  showNavigationBar: true,
);
```

`showNavigationBar` 默认 `true`。只有页面自行提供完整返回/关闭能力时，才可
传 `false`。

## 7. 事件与日志

可选订阅：

```dart
final subscription = StminiFlutter.events.listen((event) {
  switch (event.name) {
    case 'installed_packages_changed':
      // 新包已通过校验并可打开。
      break;
    case 'native_log':
      // 仅用于宿主的调试展示或采集策略。
      break;
  }
});
```

事件包括 `open_requested`、`web_open_requested`、`web_opened`、
`installed_packages_changed`、`native_log` 与 `network_log`。Release 下组件不向
Xcode 控制台打印调试日志，但保留 EventChannel，以便宿主按自身策略处理。

## 8. 发布与升级组件

1. 在本仓库修改通用代码、README 或 iOS 隐私清单。
2. 运行 `flutter test`；iOS 改动应额外执行一次宿主 `flutter build ios`。
3. 提交并推送仓库，打 tag 或记录 commit。
4. 宿主更新 Git `ref`，运行 `flutter pub get`，再执行 iOS 构建。

不要在 `Documents/STMini` 中直接修改已下载 ZIP；该目录是运行时安装产物。
Mini H5 更新应重新打 ZIP，并配套提升 `mini-manifest.json` 和宿主链接中的
版本策略。

## 9. 接入验收

- `flutter pub get` 能解析 `stmini_flutter`。
- iOS `pod install` 与 `flutter build ios` 成功。
- 首次启动可下载并进入 Mini；断网重启可复用已校验本地包。
- Mini H5 的 `getPackageName` 返回当前宿主的包名。
- 升高 `minSupportVersion` 后会下载新包。
- Mini 内 `/web` 与直接 `openWeb` 的导航栏行为符合页面需要。
- 组件源码中不出现宿主 App 的包名、CDN、品牌或业务域名。
