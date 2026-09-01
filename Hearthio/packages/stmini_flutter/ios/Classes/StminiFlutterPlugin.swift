import Flutter
import MBProgressHUD
import Photos
import Toast_Swift
import UIKit

/// iOS bridge for the generic STMini container.
///
/// This class intentionally does not import a business App's login, account,
/// router or trading code. STMini itself owns package handling and framework
/// APIs; the plugin supplies only safe, generic host UI/language/log behavior.
public final class StminiFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let maximumMiniStorageBytes = 1_048_576
  /// Base64 expands binary data by roughly one third. Keep the encoded input
  /// bounded before decoding so an untrusted Mini cannot exhaust host memory.
  private static let maximumMiniImageBase64Bytes = 26_214_400
  private var eventSink: FlutterEventSink?
  private weak var presentingViewController: UIViewController?
  private var initialized = false
  /// Optional, JSON-compatible context supplied by the embedding Flutter app.
  /// STMini stays reusable: it never imports a host's account/login module.
  private var bridgeContext: [String: Any] = [:]

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = StminiFlutterPlugin()
    let methodChannel = FlutterMethodChannel(
      name: "stmini_flutter/methods", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(
      name: "stmini_flutter/events", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      let arguments = call.arguments as? [String: Any] ?? [:]
      configureIfNeeded(
        loadingImage: arguments["loadingImage"] as? String,
        bridgeContext: arguments["bridgeContext"] as? [String: Any])
      result(nil)
    case "openMini":
      guard let arguments = call.arguments as? [String: Any],
            let link = arguments["link"] as? String,
            link.lowercased().hasPrefix("mini://") else {
        result(FlutterError(code: "invalid_mini_link", message: "link must start with mini://", details: nil))
        return
      }
      configureIfNeeded(loadingImage: nil, bridgeContext: nil)
      guard let controller = currentPresentingViewController() else {
        result(FlutterError(code: "no_presenting_controller", message: "No active Flutter view controller", details: nil))
        return
      }
      presentingViewController = controller
      emit("open_requested", ["link": redactedMiniLink(link)])
      DispatchQueue.main.async {
        STWebOpenHandler.openWeb(url: link, params: nil, crl: controller, navi: nil)
        result(nil)
      }
    case "openWeb":
      guard let arguments = call.arguments as? [String: Any],
            let url = arguments["url"] as? String,
            let webURL = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)),
            let scheme = webURL.scheme?.lowercased(),
            (scheme == "https" || scheme == "http"),
            webURL.host != nil else {
        result(FlutterError(code: "invalid_web_url", message: "url must be an absolute http(s) URL", details: nil))
        return
      }
      configureIfNeeded(loadingImage: nil, bridgeContext: nil)
      guard let controller = currentPresentingViewController() else {
        result(FlutterError(code: "no_presenting_controller", message: "No active Flutter view controller", details: nil))
        return
      }
      let showNavigationBar = arguments["showNavigationBar"] as? Bool ?? true
      let title = arguments["title"] as? String
      var params = ["isNeedNavigationBar": showNavigationBar ? "true" : "false"]
      if let title, !title.isEmpty {
        params["title"] = title
      }
      emit("web_open_requested", ["url": redactedWebURL(webURL)])
      DispatchQueue.main.async {
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let config = STWebConfig(webMode: .h5, params: params)
        STWebOpenHandler.openH5(url: webURL.absoluteString, config: config, navi: navigationController)
        navigationController.isNavigationBarHidden = !showNavigationBar
        controller.present(navigationController, animated: true) {
          self.emit("web_opened", ["url": self.redactedWebURL(webURL)])
          result(nil)
        }
      }
    case "closeMini":
      DispatchQueue.main.async { [weak self] in
        guard let controller = self?.currentPresentingViewController() else {
          result(nil)
          return
        }
        controller.dismiss(animated: true) {
          self?.emit("closed", [:])
          result(nil)
        }
      }
    case "isAvailable":
      result(true)
    case "installedPackages":
      result(installedPackagesPayload())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func configureIfNeeded(loadingImage: String?, bridgeContext: [String: Any]?) {
    if let bridgeContext {
      self.bridgeContext = bridgeContext
    }
    let handle = STWebPersonalHandle.sharedInstance()
    if let loadingImage, !loadingImage.isEmpty {
      handle.loadingImg = loadingImage
    }
    guard !initialized else { return }
    initialized = true

    handle.darkModeHandle = { UITraitCollection.current.userInterfaceStyle == .dark }
    handle.logHandle = { [weak self] message in
      self?.emit("native_log", ["message": message])
    }
    handle.apiHandle = { [weak self] message, webView in
      self?.handleGenericHostAPI(message, webView: webView)
        ?? ["handled": 0]
    }
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(installedPackagesDidChange(_:)),
      name: Notification.Name(STMiniPackageRegistry.installedPackagesDidChangeNotificationName()),
      object: nil)
  }

  /// Generic APIs that are useful in any host. Business methods deliberately
  /// return `handled: 0`, allowing STMini framework APIs to run or the Mini to
  /// receive a clear unsupported-method response.
  private func handleGenericHostAPI(_ message: [String: Any], webView: STMiniWebView) -> [String: Any] {
    let method = message["method"] as? String ?? ""
    let params = message["params"] as? [String: Any] ?? [:]
    switch method {
    case "showToast":
      let title = (params["title"] as? String) ?? (params["msg"] as? String) ?? ""
      let duration = toastDuration(params["duration"])
      DispatchQueue.main.async {
        (webView.bindCrl?.view ?? self.currentPresentingViewController()?.view)?.makeToast(title, duration: duration)
      }
      return success()
    case "showLoading":
      let title = (params["title"] as? String) ?? (params["message"] as? String) ?? ""
      DispatchQueue.main.async {
        guard let view = webView.bindCrl?.view ?? self.currentPresentingViewController()?.view else { return }
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = title
      }
      return success()
    case "hideLoading":
      DispatchQueue.main.async {
        guard let view = webView.bindCrl?.view ?? self.currentPresentingViewController()?.view else { return }
        MBProgressHUD.hide(for: view, animated: true)
      }
      return success()
    case "close":
      DispatchQueue.main.async {
        self.closeMiniPage(webView: webView, params: params)
      }
      return success()
    case "more":
      DispatchQueue.main.async {
        (webView.bindCrl as? STWebH5Crl)?.more()
      }
      return success()
    case "setStatusBarTextColor":
      let isDark = bridgeBool(params["isDark"]) ?? true
      DispatchQueue.main.async {
        webView.bindCrl?.currentStatusBarStyle = isDark ? .darkContent : .lightContent
        webView.bindCrl?.setNeedsStatusBarAppearanceUpdate()
      }
      return success()
    case "getStatusBarHeight":
      let height = mainThreadValue { statusBarHeight(for: webView) }
      return success(["height": String(format: "%.6f", height)])
    case "setClipBoardData":
      guard let text = params["text"] as? String else { return failure("缺少 text") }
      DispatchQueue.main.async {
        UIPasteboard.general.string = text
      }
      return success()
    case "jumpWeb":
      guard let url = httpURL(from: params["url"]) else { return failure("url不合法") }
      DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:])
      }
      return success()
    case "systemShareText":
      guard let text = params["text"] as? String else { return failure("缺少 text") }
      presentShareSheet(items: [text], from: webView)
      return success()
    case "systemShareUrl":
      guard let url = httpURL(from: params["urlStr"]) else {
        return params["urlStr"] == nil ? failure("缺少 urlStr") : failure("url不合法")
      }
      presentShareSheet(items: [url], from: webView)
      return success()
    case "systemShareImage":
      guard let rawImage = params["imgFileStr"] as? String else { return failure("缺少 imgFileStr") }
      guard isValidMiniImageInput(rawImage) else { return failure("图片数据过大") }
      guard let image = image(fromBase64: rawImage) else { return failure("分享图片数据有误") }
      presentShareSheet(items: [image], from: webView)
      return success()
    case "saveImageToPhotosAlbum":
      guard let rawImage = params["imgFileStr"] as? String else { return failure("缺少 imgFileStr") }
      guard isValidMiniImageInput(rawImage) else { return failure("图片数据过大") }
      guard let image = image(fromBase64: rawImage) else { return failure("图片数据有误") }
      saveImageToPhotoLibrary(image, params: params, webView: webView)
      return ["handled": 2]
    case "showPopWeb":
      guard let url = miniPopupURL(from: params["url"]) else { return failure("url不合法") }
      let margins = mainThreadValue {
        popupMargins(left: params["left"], right: params["right"])
      }
      let ratio = boundedRatio(params["ratio"], fallback: 1)
      DispatchQueue.main.async {
        let popup = STWebPopView(leftMargin: margins.left, rightMargin: margins.right, aspectRatio: ratio, url: url)
        popup.callback = { [weak webView] _, _ in
          DispatchQueue.main.async {
            webView?.bindCrl?.viewWillAppear(true)
          }
        }
        popup.showAt(self.currentPresentingViewController()?.view ?? webView)
      }
      return success()
    case "codeVerifSucc":
      DispatchQueue.main.async {
        if webView.environment == .pop, let popup = webView.superview as? STWebPopView {
          popup.complete(info: params)
        }
      }
      return success()
    case "getConfig":
      return success(bridgeConfig(for: webView))
    case "getLanguage":
      return ["handled": 1, "code": "1", "data": ["language": normalizedLanguage()]]
    case "setStorage":
      return setMiniStorage(params)
    case "getStorage":
      return getMiniStorage(params)
    case "getPackageName":
      // Package identity belongs to the embedding host. Returning an empty
      // value by default keeps this reusable component free of business IDs.
      let packageName = (bridgeContext["packageName"] as? String) ?? ""
      return success(["packageName": packageName])
    case "getUserInfo":
      return success(bridgeUserInfo())
    case "getToken":
      let hostToken = (bridgeContext["userInfo"] as? [String: Any])?["token"] as? String
      return success(hostToken ?? storedBridgeUserInfo()["token"] as? String ?? "")
    case "applog":
      if let message = params["msg"] ?? params["message"] {
        STProjectHelper.Log("Mini applog: \(String(describing: message))")
      }
      return success()
    case "logNetworkRequest":
      emit("network_log", sanitizedNetworkLog(params))
      return ["handled": 1, "code": "1", "data": ["recorded": true]]
    default:
      return ["handled": 0]
    }
  }

  private func success(_ data: Any = [:]) -> [String: Any] {
    ["handled": 1, "code": "1", "data": data]
  }

  /// Mirror the standard iOS H5 bridge close contract.  A missing count closes
  /// the current Mini-owned page; zero returns to the Mini root (or dismisses
  /// a standalone page); a positive count pops that many navigation levels.
  private func closeMiniPage(webView: STMiniWebView, params: [String: Any]) {
    guard let controller = webView.bindCrl else { return }
    guard let rawCount = params["count"] else {
      controller.close()
      return
    }

    let count: Int
    if let number = rawCount as? NSNumber {
      count = number.intValue
    } else if let string = rawCount as? String, let parsed = Int(string) {
      count = parsed
    } else {
      controller.close()
      return
    }

    guard count >= 0 else {
      controller.close()
      return
    }
    guard let navigationController = controller.navigationController else {
      controller.dismiss(animated: true)
      return
    }
    if count == 0 {
      navigationController.popToRootViewController(animated: true)
      return
    }
    let targetIndex = navigationController.viewControllers.count - 1 - count
    guard targetIndex >= 0 else {
      controller.close()
      return
    }
    navigationController.popToViewController(
      navigationController.viewControllers[targetIndex],
      animated: true)
  }

  /// The ordinary iOS bridge stores validated JSON text in UserDefaults and
  /// deserializes it when reading. Do the same here: UserDefaults never sees
  /// an NSNull/property-list-incompatible object, while H5 receives its
  /// original JSON value.
  private func setMiniStorage(_ params: [String: Any]) -> [String: Any] {
    guard let key = validMiniStorageKey(params["key"]) else {
      return failure("缺少key")
    }
    guard let value = params["data"] as? String else {
      return failure("应当存储json字符串")
    }
    guard value.lengthOfBytes(using: .utf8) <= Self.maximumMiniStorageBytes else {
      return failure("存储内容过大")
    }
    guard jsonValue(from: value) != nil else {
      return failure("存储出错")
    }
    UserDefaults.standard.set(value, forKey: key)
    return success()
  }

  private func getMiniStorage(_ params: [String: Any]) -> [String: Any] {
    guard let key = validMiniStorageKey(params["key"]) else {
      return failure("缺少key")
    }
    guard let stored = UserDefaults.standard.object(forKey: key) else {
      return failure("值不存在")
    }
    if let value = stored as? String {
      // Preserve the legacy iOS contract: old non-JSON strings remain
      // readable as strings, while all current JSON snapshot values decode.
      return success(jsonValue(from: value) ?? value)
    }
    return success(stored)
  }

  private func validMiniStorageKey(_ rawKey: Any?) -> String? {
    guard let key = rawKey as? String,
          !key.isEmpty,
          key.count <= 256 else {
      return nil
    }
    return key
  }

  private func jsonValue(from value: String) -> Any? {
    guard let data = value.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  private func bridgeBool(_ value: Any?) -> Bool? {
    if let value = value as? Bool { return value }
    if let value = value as? NSNumber { return value.boolValue }
    guard let text = value as? String else { return nil }
    switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "1", "true", "yes", "on": return true
    case "0", "false", "no", "off": return false
    default: return nil
    }
  }

  private func toastDuration(_ value: Any?) -> TimeInterval {
    let duration: TimeInterval
    if let number = value as? NSNumber { duration = number.doubleValue }
    else if let text = value as? String, let number = Double(text) { duration = number }
    else { duration = 1 }
    return min(max(duration, 0.1), 10)
  }

  /// Keep the common iOS bridge schema even when a reusable host does not
  /// supply product-specific endpoints. Hosts may override any field through
  /// `bridgeContext.config`; STMini never imports their configuration module.
  private func bridgeConfig(for webView: STMiniWebView) -> [String: Any] {
    var result: [String: Any] = [
      "isChild": webView.isChild ? "1" : "0",
      "baseHost": "",
      "captchaApiKey": "",
      "channel": "",
    ]
    if let config = bridgeContext["config"] as? [String: Any] {
      result.merge(config) { _, hostValue in hostValue }
    }
    return result
  }

  private func statusBarHeight(for webView: STMiniWebView) -> CGFloat {
    if #available(iOS 13.0, *),
       let height = webView.bindCrl?.view.window?.windowScene?.statusBarManager?.statusBarFrame.height,
       height > 0 {
      return height
    }
    return webView.bindCrl?.view.safeAreaInsets.top ?? 0
  }

  private func httpURL(from value: Any?) -> URL? {
    guard let raw = value as? String,
          let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
          let scheme = url.scheme?.lowercased(),
          ["http", "https"].contains(scheme),
          url.host?.isEmpty == false else {
      return nil
    }
    return url
  }

  private func miniPopupURL(from value: Any?) -> String? {
    guard let raw = value as? String else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if httpURL(from: value) != nil || value.hasPrefix(STMiniPrefix.local) {
      return value
    }
    return nil
  }

  private func image(fromBase64 rawValue: String) -> UIImage? {
    let payload = rawValue.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).last
    guard let payload,
          let data = Data(base64Encoded: String(payload), options: .ignoreUnknownCharacters) else {
      return nil
    }
    return UIImage(data: data)
  }

  private func isValidMiniImageInput(_ rawValue: String) -> Bool {
    rawValue.lengthOfBytes(using: .utf8) <= Self.maximumMiniImageBase64Bytes
  }

  private func boundedInt(_ value: Any?, fallback: Int, range: ClosedRange<Int>) -> Int {
    let parsed: Int?
    if let value = value as? NSNumber { parsed = value.intValue }
    else if let value = value as? String { parsed = Int(value) }
    else { parsed = nil }
    return min(max(parsed ?? fallback, range.lowerBound), range.upperBound)
  }

  private func boundedRatio(_ value: Any?, fallback: CGFloat) -> CGFloat {
    let parsed: CGFloat?
    if let value = value as? NSNumber { parsed = CGFloat(value.doubleValue) }
    else if let value = value as? String, let number = Double(value) { parsed = CGFloat(number) }
    else { parsed = nil }
    return min(max(parsed ?? fallback, 0.2), 3)
  }

  private func popupMargins(left: Any?, right: Any?) -> (left: Int, right: Int) {
    var leftMargin = boundedInt(left, fallback: 50, range: 0...160)
    var rightMargin = boundedInt(right, fallback: 50, range: 0...160)
    // STWebPopView derives its width by subtracting both margins. Keep at
    // least 120pt for the child WebView even on the narrowest phone screen.
    let maximumTotal = max(0, Int(UIScreen.main.bounds.width.rounded(.down)) - 120)
    if leftMargin + rightMargin > maximumTotal {
      leftMargin = min(leftMargin, maximumTotal)
      rightMargin = min(rightMargin, maximumTotal - leftMargin)
    }
    return (leftMargin, rightMargin)
  }

  private func mainThreadValue<T>(_ operation: () -> T) -> T {
    if Thread.isMainThread { return operation() }
    return DispatchQueue.main.sync(execute: operation)
  }

  private func presentShareSheet(items: [Any], from webView: STMiniWebView) {
    DispatchQueue.main.async {
      guard let controller = webView.bindCrl ?? self.currentPresentingViewController() else { return }
      let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
      if let popover = activity.popoverPresentationController {
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
      }
      controller.present(activity, animated: true)
    }
  }

  private func saveImageToPhotoLibrary(_ image: UIImage, params: [String: Any], webView: STMiniWebView) {
    let complete: (Bool, String?) -> Void = { [weak self, weak webView] saved, message in
      guard let self, let webView else { return }
      let result: [String: Any] = saved
        ? ["code": "1", "data": [:]]
        : ["code": "0", "data": ["msg": message ?? "保存出错"]]
      self.deliverAsyncCallback(method: "saveImageToPhotosAlbum", params: params, result: result, webView: webView)
    }
    let write = {
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { saved, _ in
        complete(saved, saved ? nil : "保存出错")
      }
    }

    if #available(iOS 14, *) {
      switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
      case .authorized, .limited:
        write()
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
          if status == .authorized || status == .limited { write() }
          else { complete(false, "没有权限") }
        }
      default:
        complete(false, "没有权限")
      }
    } else {
      switch PHPhotoLibrary.authorizationStatus() {
      case .authorized:
        write()
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization { status in
          if status == .authorized { write() }
          else { complete(false, "没有权限") }
        }
      default:
        complete(false, "没有权限")
      }
    }
  }

  private func deliverAsyncCallback(method: String, params: [String: Any], result: [String: Any], webView: STMiniWebView) {
    var model = STWebApiModel(dict: ["method": method, "params": params])
    model.webview = webView
    DispatchQueue.main.async {
      STWebApiManager.callBack(result, model: model)
    }
  }

  private func bridgeUserInfo() -> [String: Any] {
    let isDark = currentPresentingViewController()?.traitCollection.userInterfaceStyle == .dark
    var result: [String: Any] = [
      "device_type": "ios",
      "dark_mode": isDark ? "1" : "0",
      "language_code": normalizedLanguage(),
    ]
    result.merge(storedBridgeUserInfo()) { _, storedValue in storedValue }
    // A host that owns authentication may supply its normal H5 bridge payload
    // through `initialize({ bridgeContext: { userInfo: ... } })`.
    if let userInfo = bridgeContext["userInfo"] as? [String: Any] {
      result.merge(userInfo) { _, hostValue in hostValue }
    }
    return result
  }

  /// The host explicitly selects the Mini-owned JSON storage key. This avoids
  /// inspecting unrelated app defaults while allowing a reusable STMini host
  /// to expose the conventional iOS H5 session fields to an online page.
  private func storedBridgeUserInfo() -> [String: Any] {
    guard let storageKey = bridgeContext["authStorageKey"] as? String,
          let jsonText = UserDefaults.standard.string(forKey: storageKey),
          let values = jsonValue(from: jsonText) as? [String: Any] else {
      return [:]
    }
    var result: [String: Any] = [:]
    result["token"] = values["token"] ?? values["access_token"]
    result["device_id"] = values["device_id"]
    result["user_id"] = values["user_id"]
    return result.compactMapValues { $0 }
  }

  private func failure(_ message: String) -> [String: Any] {
    ["handled": 1, "code": "0", "data": ["msg": message]]
  }

  @objc private func installedPackagesDidChange(_ notification: Notification) {
    var payload = installedPackagesPayload()
    if let miniId = notification.userInfo?["miniId"] as? String {
      payload["miniId"] = miniId
    }
    if let version = notification.userInfo?["version"] as? String {
      payload["version"] = version
    }
    DispatchQueue.main.async { [weak self] in
      self?.emit("installed_packages_changed", payload)
    }
  }

  private func installedPackagesPayload() -> [String: Any] {
    let packages = STMiniPackageRegistry.installedPackages().map { item in
      [
        "miniId": item.miniId,
        "miniName": item.miniName,
        "iconUrl": item.iconURL,
        "launchLink": item.launchLink,
      ]
    }
    return ["packages": packages]
  }

  private func normalizedLanguage() -> String {
    let language = Locale.preferredLanguages.first?.lowercased() ?? "en"
    if language.hasPrefix("zh-hant") || language.contains("hant") || language.hasPrefix("zh-tw") || language.hasPrefix("zh-hk") {
      return "zh-Hant"
    }
    if language.hasPrefix("zh") { return "zh-Hans" }
    return language.hasPrefix("en") ? "en-US" : language
  }

  private func currentPresentingViewController() -> UIViewController? {
    let root: UIViewController?
    if #available(iOS 13.0, *) {
      root = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
        .first?.rootViewController
    } else {
      root = UIApplication.shared.keyWindow?.rootViewController
    }
    return topController(from: root)
  }

  private func redactedWebURL(_ url: URL) -> String {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return url.scheme.map { "\($0)://<invalid>" } ?? "<invalid>"
    }
    components.query = nil
    components.fragment = nil
    return components.string ?? "<invalid>"
  }

  private func topController(from controller: UIViewController?) -> UIViewController? {
    if let navigation = controller as? UINavigationController {
      return topController(from: navigation.visibleViewController)
    }
    if let tab = controller as? UITabBarController {
      return topController(from: tab.selectedViewController)
    }
    if let presented = controller?.presentedViewController, !presented.isBeingDismissed {
      return topController(from: presented)
    }
    return controller
  }

  private func sanitizedNetworkLog(_ params: [String: Any]) -> [String: Any] {
    var log: [String: Any] = [:]
    for key in ["phase", "method", "status", "error"] {
      if let value = params[key] { log[key] = value }
    }
    if let rawURL = params["url"] as? String,
       var components = URLComponents(string: rawURL) {
      components.query = nil
      log["url"] = components.string ?? ""
    }
    return log
  }

  private func redactedMiniLink(_ link: String) -> String {
    guard var components = URLComponents(string: link) else { return "mini://" }
    components.query = nil
    return components.string ?? "mini://"
  }

  private func emit(_ name: String, _ payload: [String: Any]) {
    eventSink?(["name": name, "payload": payload])
  }
}
