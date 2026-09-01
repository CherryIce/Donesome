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

Add the package dependency in the Flutter App:

```yaml
dependencies:
  stmini_flutter:
    path: packages/stmini_flutter
```

The iOS plugin vendors the STMini sources and resource bundle, so the Flutter
App does not reference another App project's absolute path. Run `flutter pub
get`; Flutter registers the iOS plugin automatically. The host deployment
target must be iOS 13 or later.

The component contains no application package identifier. If an H5 bridge
needs one, the embedding host may provide it explicitly:

```dart
await StminiFlutter.initialize(
  bridgeContext: {'packageName': 'com.example.app'},
);
```

Without this optional value, `getPackageName` returns an empty string.

For production, keep this package in its own repository or private package
registry and version the vendored `ios/STMini` snapshot together with the
plugin. Do not edit the installed package in `Documents/STMini` directly.

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

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
