# stmini_flutter

`stmini_flutter` is a Flutter wrapper around the iOS STMini runtime. It is a
**generic Mini-program container**, not a copy of any business App module.

## Included iOS capabilities

- `mini://` opening from a Flutter page, a CMS Grid link or scanner result.
- ZIP download, retry, manifest verification, safe extraction and atomic
  install under `Documents/STMini/<miniId>/`.
- Local package reuse, version/minimum-version decision, forced and silent
  package update, and package-list change events.
- Native Mini loading UI, capsule controls, local Mini subpages, Mini-internal
  `/web` interception, normal FIFO keep-alive and STMini lifecycle handling.
- Generic host bridge methods: `showToast`, `showLoading`, `hideLoading`,
  `getLanguage`, and `logNetworkRequest`.

It deliberately does **not** provide accounts, login token injection,
authorisation, trading, MCP, quant storage, a business Router or a server API.
Those belong to the embedding App and can later be registered as a separate
host adapter with an explicit security policy.

## Flutter use

```dart
await StminiFlutter.initialize();

await StminiFlutter.openMini(
  'mini://examplemini?'
  'downloadUrl=https%3A%2F%2Fcdn.example.com%2Fexamplemini-1.0.0.zip&'
  'currentVersion=1.0.0&minSupportVersion=1.0.0',
);

// Open an external H5 page without creating a Mini ZIP package.
await StminiFlutter.openWeb(
  'https://example.com/help',
  title: 'Help',
);

StminiFlutter.events.listen((event) {
  if (event.name == 'installed_packages_changed') {
    // Re-read installedPackages() and refresh the Flutter Grid.
  }
});
```

Only `miniId` is mandatory in a link. `downloadUrl`, `currentVersion`,
`minSupportVersion`, `miniName`, `miniNameEn`, `iconUrl`, and `path` are
optional. Keep the link contract identical for QR and Grid; a generated local
entry should normally use only `mini://<miniId>`.

`openWeb` accepts an absolute `http(s)` URL and presents it in the same native
H5 container. Its navigation bar is shown by default; use
`showNavigationBar: false` only for an H5 page that supplies its own complete
back/close flow.

## Host integration

完整中文接入文档见 [docs/host-integration.md](docs/host-integration.md)。

Add the package dependency in the Flutter App:

```yaml
dependencies:
  stmini_flutter:
    git:
      url: https://github.com/fsst-ios/stmini_flutter.git
      ref: main
```

The iOS plugin vendors the STMini sources and resource bundle, so the Flutter
App does not reference another App project's absolute path. Run `flutter pub
get`; Flutter registers the iOS plugin automatically. The host deployment
target must be iOS 13 or later.

### 宿主配置：包名和 Mini 包链接

`stmini_flutter` 不保存任何品牌、业务包名、Mini ID、下载域名或版本号。
这些值均由各个宿主 App 自己提供；组件只负责解析 `mini://`、下载、校验、
安装和打开 Mini。

宿主启动后，在 Flutter 首帧完成时初始化组件并打开自己的 Mini：

```dart
import 'package:stmini_flutter/stmini_flutter.dart';

Future<void> openHomeMini() async {
  await StminiFlutter.initialize(
    bridgeContext: const {
      // H5 调用 getPackageName 时返回宿主自己的包名。
      'packageName': 'com.example.host',
    },
  );

  await StminiFlutter.openMini(
    'mini://examplemini?'
    'downloadUrl=https%3A%2F%2Fcdn.example.com%2Fexamplemini-1.0.0.zip&'
    'currentVersion=1.0.0&'
    'minSupportVersion=1.0.0&'
    'miniName=Example%20Mini&'
    'miniNameEn=Example',
  );
}
```

其中：

- `packageName` 可省略；省略时 H5 的 `getPackageName` 返回空字符串。
- `mini://<miniId>` 是 Mini 的唯一标识；每个宿主自行决定其值。
- `downloadUrl`、`currentVersion`、`minSupportVersion`、名称和图标均属于
  宿主的发布配置，不写入组件。
- 替换品牌或接入另一个宿主时，通常仅需替换上述 `packageName` 和 Mini 链接。

若宿主有额外的登录态同步或 H5 存储约定，也必须通过可选 `bridgeContext`
显式传入；组件不会默认读取宿主业务数据或猜测任何存储键。

The component contains no application package identifier, Mini ID, CDN address
or business domain. Each embedding host provides its own package identifier and
its own `mini://` package link. If an H5 bridge needs the package identifier,
the host provides it explicitly:

```dart
await StminiFlutter.initialize(
  bridgeContext: {'packageName': 'com.example.app'},
);
```

Without this optional value, `getPackageName` returns an empty string.

Version the vendored `ios/STMini` snapshot together with this plugin. Do not
edit a downloaded package in `Documents/STMini` directly.

## Events and package list

`StminiFlutter.events` emits:

- `open_requested`: an opening request was forwarded to STMini; query content
  is redacted.
- `web_open_requested` / `web_opened`: a host requested or presented an
  external H5 page; URL query and fragment are redacted.
- `installed_packages_changed`: a package passed verification and became
  available. The event contains `miniId`, `version` and the current `packages`
  list.
- `native_log`: STMini native diagnostic text.
- `network_log`: a Mini called the generic logging API; URL query is removed.

`StminiFlutter.installedPackages()` returns only validated runnable packages,
not failed download staging directories.
