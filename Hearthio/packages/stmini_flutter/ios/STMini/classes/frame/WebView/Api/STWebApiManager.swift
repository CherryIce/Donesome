






import Foundation
import UIKit


@objc public class STWebApiManager: NSObject, STWebApiHandler {

    /// Quant APIs are a Mini capability, not ordinary H5 APIs.  Keep the
    /// recognition and isolation inside STMini even though an embedding App
    /// supplies the account/MCP implementation through `quantMiniApiHandle`.
    private static let quantMiniMethods: Set<String> = [
        "getQuantSession",
        "refreshQuantSession",
        "getQuantBootstrap",
        "saveQuantLocalSnapshot",
        "resetQuantLocalRecords",
    ]

    /// `JSONSerialization` raises an Objective-C exception (rather than a
    /// Swift `throw`) for NaN / +/-Infinity.  API data ultimately comes from
    /// the trading bridge, so one malformed numeric value must never be able
    /// to terminate the host process while replying to H5.
    private static func jsonCompatibleObject(_ value: Any) -> Any {
        if value is NSNull || value is String {
            return value
        }
        if let number = value as? NSNumber {
            // CFBoolean is also bridged as NSNumber.  It is always a valid
            // JSON value and must not be treated as a floating-point number.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number
            }
            if number.doubleValue.isFinite {
                return number
            }
            STProjectHelper.Log("STWebApiManager: 非有限数值已替换为 null，避免 JSON 回调导致宿主闪退")
            return NSNull()
        }
        if let dictionary = value as? [String: Any] {
            var sanitized: [String: Any] = [:]
            dictionary.forEach { key, item in
                sanitized[key] = jsonCompatibleObject(item)
            }
            return sanitized
        }
        if let dictionary = value as? [AnyHashable: Any] {
            var sanitized: [String: Any] = [:]
            dictionary.forEach { key, item in
                sanitized[String(describing: key)] = jsonCompatibleObject(item)
            }
            return sanitized
        }
        if let array = value as? [Any] {
            return array.map { jsonCompatibleObject($0) }
        }
        // The bridge contract is JSON only.  Preserve the callback shape for
        // unexpected Foundation/custom objects without serializing them via
        // description (which could leak implementation details to H5).
        STProjectHelper.Log("STWebApiManager: 非 JSON 回调值已替换为 null，type=\(String(describing: type(of: value)))")
        return NSNull()
    }

    private static func jsonString(_ object: [String: Any]) -> String? {
        guard let sanitized = jsonCompatibleObject(object) as? [String: Any],
              JSONSerialization.isValidJSONObject(sanitized) else {
            STProjectHelper.Log("STWebApiManager: 回调对象不是有效 JSON")
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: sanitized, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            STProjectHelper.Log("STWebApiManager: JSON 回调序列化失败：\(error.localizedDescription)")
            return nil
        }
    }

    /// Bridge responses frequently contain a complete local-storage snapshot.
    /// Formatting that payload for a debug log can take longer than the
    /// callback itself and also exposes credentials in Xcode.  Keep the
    /// diagnostic useful without walking or printing user data.
    private static func callbackLogSummary(_ params: [String: Any], method: String, methodId: String) -> String {
        let code = params["code"].map { String(describing: $0) } ?? "<none>"
        let dataSummary: String
        switch params["data"] {
        case let value as [String: Any]:
            dataSummary = "object(count=\(value.count))"
        case let value as [Any]:
            dataSummary = "array(count=\(value.count))"
        case let value as String:
            dataSummary = "string(length=\(value.utf8.count))"
        case nil:
            dataSummary = "none"
        default:
            dataSummary = "type=\(String(describing: type(of: params["data"]!)))"
        }
        return "api callback method=\(method) code=\(code) methodId=\(methodId) data=\(dataSummary)"
    }
    
    
    static func dealWithApiMessage(_ message: Any, webView: STMiniWebView) {
        
        guard let messageDic = message as? [String: Any] else {
            STProjectHelper.Log("js调用原生api方法，message需为map格式 \n messageDic: \(message)")
            return
        }
        guard (messageDic["method"] as? String) != nil else {
            STProjectHelper.Log("js调用原生api方法，method不能为空 \n messageDic: \(message)")
            return
        }
        guard (messageDic["params"] as? [String: Any]) != nil else {
            STProjectHelper.Log("js调用原生api方法，params不能为空，没有参数传空map \n messageDic: \(message)")
            return
        }
                
        
        var model = STWebApiModel.init(dict: messageDic)
        model.webview = webView
        if model.method == "open" {
            let router = model.params["router"] as? String ?? "<empty>"
            let link = (model.params["link"] as? String ?? "<empty>").split(separator: "?").first ?? "<empty>"
            let caller = String(describing: type(of: webView.bindCrl))
#if DEBUG
            NSLog("[STMini][bridge-open] router=%@ link=%@ caller=%@", router, String(link), caller)
#endif
        }
        // A Mini must not hand its `/web` route back to the host router.  It
        // stays in the Mini navigation stack so root identity and Mini API
        // permissions continue to apply to the online second-level page.
        if let miniOpenResult = STWebRouterApi().openInternalWebIfNeeded(model: model) {
            STWebApiManager.callBack(miniOpenResult, model: model)
            return
        }
        if let miniRouteResult = STWebRouterApi().forwardMiniRouteOpenIfNeeded(model: model) {
            STWebApiManager.callBack(miniRouteResult, model: model)
            return
        }

        
        
        let infoDic: [String : Any] = ["method": model.method, "params": model.params]
        var result: [String : Any] = [:]
        if quantMiniMethods.contains(model.method) {
            // A quant method may only originate from a Mini root or from an
            // H5 page pushed by that root through mini_navigateTo.  Local
            // downloaded Minis are deliberately included here; package and
            // channel ownership are then verified by the host adapter.
            guard miniRootController(for: webView) != nil else {
                STWebApiManager.callBack([
                    "code": "0",
                    "data": ["msg": "仅量化小程序页面可调用该能力"],
                ], model: model)
                return
            }
            guard let quantHandle = STWebPersonalHandle.sharedInstance().quantMiniApiHandle else {
                STWebApiManager.callBack([
                    "code": "0",
                    "data": ["msg": "宿主未提供量化小程序能力"],
                ], model: model)
                return
            }
            result = quantHandle(infoDic, webView)
            if let handled = result["handled"] as? Int {
                result.removeValue(forKey: "params")
                result.removeValue(forKey: "handled")
                if handled == 1 {
                    STWebApiManager.callBack(result, model: model)
                } else if handled != 2 {
                    STWebApiManager.callBack([
                        "code": "0",
                        "data": ["msg": "量化小程序 API 未处理"],
                    ], model: model)
                }
                return
            }
            // A host adapter must explicitly finish or mark an async request.
            // Do not fall through to the ordinary H5 handler and accidentally
            // expose a quant method to a non-Mini implementation.
            STWebApiManager.callBack([
                "code": "0",
                "data": ["msg": "量化小程序 API 返回无效"],
            ], model: model)
            return
        }
        if (STWebPersonalHandle.sharedInstance().apiHandle != nil) {
            result = STWebPersonalHandle.sharedInstance().apiHandle!(infoDic, webView)
        }
        if result["handled"] != nil {
            if result["handled"] as! Int == 1 {
                result.removeValue(forKey: "params")
                result.removeValue(forKey: "handled")
                STWebApiManager.callBack(result, model: model)
                return
            }
            else if result["handled"] as! Int == 2 {
                STProjectHelper.Log("method<\(model.method)>延迟处理")
                return
            }
        }
        
        
        result.removeValue(forKey: "params")
        result.removeValue(forKey: "handled")
        if model.method == "mini_getMiniProgramContinuousKeepAlive" {
            result = STWebApiManager.continuousKeepAliveState(model: model, enabled: nil)
        }
        else if model.method == "mini_setMiniProgramContinuousKeepAlive" {
            let rawEnabled = model.params["enabled"]
            let enabled: Bool
            if let boolValue = rawEnabled as? Bool {
                enabled = boolValue
            } else if let numberValue = rawEnabled as? NSNumber {
                enabled = numberValue.boolValue
            } else if let textValue = rawEnabled as? String {
                enabled = ["1", "true", "yes", "on"].contains(textValue.lowercased())
            } else {
                result = ["code": "0", "data": ["msg": "缺少 enabled"]]
                STWebApiManager.callBack(result, model: model)
                return
            }
            result = STWebApiManager.continuousKeepAliveState(model: model, enabled: enabled)
        }
        else if model.method == "mini_checkMiniProgramUpdate" {
            result = STWebApiManager.checkMiniProgramUpdate(model: model)
        }
        else if model.method == "mini_downloadMiniProgramUpdate" {
            result = STWebApiManager.downloadMiniProgramUpdate(model: model)
        }
        else if model.method == "mini_navigateTo" {
            result = STWebRouterApi().navigateTo(model: model)
        }
        else if model.method == "mini_notifySessionChanged" {
            result = STWebApiManager.notifyMiniSessionChanged(model: model)
        }
        else if model.method == "open" {
            // `/web` is handled above by STWebRouterApi. Other routes belong
            // to the H5 application's own router, so return a precise bridge
            // error rather than incorrectly claiming that the `open` API is
            // unsupported.
            let route = model.params["router"] as? String
            let message = route?.isEmpty == false
                ? "路由<\(route!)>不存在"
                : "缺少 router"
            result = ["code": "0", "data": ["msg": message]]
        }
        else if model.method == "close" {
            // A package route pushed from an online `/web` page has no native
            // navigation bar. Its H5 back action calls `close`; pop only this
            // marked child so the original online page remains on the stack.
            if let child = webView.bindCrl as? STWebH5Crl,
               child.isMiniRouteChild {
                DispatchQueue.main.async {
                    child.navigationController?.popViewController(animated: true)
                }
                result = ["code": "1", "data": ["closed": true]]
            }
            else if webView.environment == STWebEnv.pop {
                if let popView = webView.superview as? STWebPopView {
                    popView.dismiss()
                }
                result = ["code": "1", "data": ["closed": true]]
            }
        }
        else {

            result["code"] = "0"
            result["data"] = ["msg": "method<\(model.method)>尚未支持"]
            STWebApiManager.callBack(result, model: model)
            return
        }
        STWebApiManager.callBack(result, model: model)















        
    }

    /// Resolves the owning Mini root for either the root WebView or a page
    /// pushed by `mini_navigateTo`. Ordinary `/web` H5 pages do not carry
    /// `isMiniInternalPage`, so they never gain Mini-only APIs merely because
    /// they also use STMiniWebView internally. Both online and locally
    /// installed Mini packages are valid roots.
    static func miniRootController(for webView: STMiniWebView?) -> STWebMiniprogramCrl? {
        guard let controller = webView?.bindCrl else { return nil }
        if let root = controller as? STWebMiniprogramCrl {
            guard !root.isChild else { return nil }
            return root
        }
        guard let child = controller as? STWebH5Crl,
              child.isMiniInternalPage,
              let navigationController = child.navigationController,
              let root = navigationController.viewControllers.first as? STWebMiniprogramCrl,
              !root.isChild else {
            return nil
        }
        return root
    }

    /// APIs that require a remotely managed Mini retain the online-only
    /// boundary. Quant APIs use `miniRootController(for:)` above because the
    /// supported package is normally a verified local download.
    static func onlineMiniRootController(for webView: STMiniWebView?) -> STWebMiniprogramCrl? {
        guard let root = miniRootController(for: webView), root.config.webMode == .online else {
            return nil
        }
        return root
    }

    /// All pages in one Mini navigation stack share the same Mini identity.
    /// A generic API is therefore rooted at that Mini, rather than restricted
    /// to whichever page happens to be visible.  Ordinary H5 remains outside
    /// this resolver and keeps only its existing H5 API surface.
    private static func continuousKeepAliveState<T>(model: T, enabled: Bool?) -> [String: Any] where T: STWebApiForm {
        guard let miniCrl = onlineMiniRootController(for: model.webview),
              let miniId = miniCrl.name,
              !miniId.isEmpty else {
            return ["code": "0", "data": ["msg": "仅小程序页面可设置持续保活"]]
        }
        let supported = STWebMiniProgramKeepAliveStore.shared.supportsContinuousKeepAlive(miniId: miniId)
        if let enabled = enabled, supported {
            STWebMiniProgramKeepAliveStore.shared.setContinuousKeepAlive(enabled, for: miniId)
        }
        return ["code": "1", "data": [
            "enabled": supported && STWebMiniProgramKeepAliveStore.shared.isContinuousKeepAliveEnabled(miniId: miniId),
            "supported": supported,
        ]]
    }

    /// Common host update-check entry for first-party Mini programs. The
    /// package manifest is authoritative so H5 cannot opt into the host path
    /// by forging a parameter. The actual unified update service is supplied
    /// later by the host through `miniProgramUpdateCheckHandle`.
    private static func checkMiniProgramUpdate<T>(model: T) -> [String: Any] where T: STWebApiForm {
        guard let miniCrl = onlineMiniRootController(for: model.webview),
              let miniId = STWebResourceManager.miniNameHandle(name: miniCrl.name).0,
              !miniId.isEmpty,
              let updateSelf = STWebResourceManager.installedMiniPackageUpdateSelf(name: miniId) else {
            return ["code": "0", "data": ["msg": "小程序包校验失败"]]
        }
        guard updateSelf == "0" else {
            return ["code": "0", "data": ["msg": "当前小程序由自身检查更新", "updateself": updateSelf]]
        }
        guard let handler = STWebPersonalHandle.sharedInstance().miniProgramUpdateCheckHandle else {
            return ["code": "0", "data": ["msg": "宿主检查更新尚未接入", "updateself": "0"]]
        }
        // Let the future host service receive H5 options, while always
        // overriding identity and update ownership with verified values.
        var request = model.params
        request["miniId"] = miniId
        request["updateself"] = "0"
        return handler(request, model.webview!)
    }

    /// Self-managed packages may use their own version-check service, but the
    /// archive itself is always downloaded, verified and atomically installed
    /// by STMini. H5 provides only the server-issued URL and force flag; the
    /// downloaded manifest, rather than an H5 version argument, is the source
    /// of package-version truth.
    private static func downloadMiniProgramUpdate<T>(model: T) -> [String: Any] where T: STWebApiForm {
        guard let miniCrl = onlineMiniRootController(for: model.webview),
              let miniId = STWebResourceManager.miniNameHandle(name: miniCrl.name).0,
              !miniId.isEmpty,
              STWebResourceManager.installedMiniPackageUpdateSelf(name: miniId) == "1" else {
            return ["code": "0", "data": ["msg": "当前小程序不支持自行更新"]]
        }
        guard let downloadURL = (model.params["downloadUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !downloadURL.isEmpty else {
            return ["code": "0", "data": ["msg": "缺少更新地址"]]
        }
        let rawForce = model.params["isforce"] ?? model.params["isForce"]
        let isForce: Bool
        if let value = rawForce as? Bool {
            isForce = value
        } else if let value = rawForce as? NSNumber {
            isForce = value.boolValue
        } else if let value = rawForce as? String {
            isForce = ["1", "true", "yes", "on"].contains(value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        } else {
            return ["code": "0", "data": ["msg": "缺少 isforce"]]
        }
        // A forced package update replaces the whole Mini runtime.  When it
        // originates from a pushed Mini page, return to the root first so the
        // native loading layer is visible instead of remaining underneath the
        // child H5 controller.
        if isForce,
           let navigationController = miniCrl.navigationController,
           navigationController.topViewController !== miniCrl {
            navigationController.popToViewController(miniCrl, animated: false)
        }
        return miniCrl.requestSelfManagedPackageUpdate(downloadURL: downloadURL, isForce: isForce)
    }
    
    
    static func sendScriptMessageWithMethod(_ method: String, params: [String: Any], webview: STMiniWebView) {
        var mutableDict =  [String: Any]()
        mutableDict["method"] = method;
        mutableDict["params"] = params;
        guard let result = jsonString(mutableDict) else { return }
        STProjectHelper.Log("sendMsg method: \(method) \nparams: \(params)")
        // Lifecycle events may arrive while the document is still parsing its
        // entry module.  Calling an undeclared global at that point throws a
        // JavaScript exception and loses the event.  The H5 bridge queues
        // later events itself, so native only needs to skip the pre-bridge
        // delivery safely.
        webview.evaluateJavaScript("if (typeof window.CMSCallJsMessage === 'function') { window.CMSCallJsMessage(\(result)); true; } else { false; }") { (info, error) in
            if error != nil {
                STProjectHelper.Log("js方法<\(method)>调用失败 错误：\(String(describing: error?.localizedDescription))")
            } else if (info as? Bool) == false {
                STProjectHelper.Log("js方法<\(method)>暂未投递：H5 Bridge 尚未就绪")
            } else {
                STProjectHelper.Log("js方法<\(method)>调用成功")
            }
        }
    }

    /// Mini-owned pages have separate JavaScript runtimes. Broadcast a
    /// credential-free session signal after either login or logout so every
    /// sibling rehydrates the exact shared auth snapshot through getStorage.
    private static func notifyMiniSessionChanged<T>(model: T) -> [String: Any] where T: STWebApiForm {
        guard let sourceWebView = model.webview,
              let source = sourceWebView.bindCrl,
              let navigationController = source.navigationController,
              miniRootController(for: model.webview) != nil else {
            return ["code": "0", "data": ["msg": "仅小程序页面可通知会话变更"]]
        }

        let rawReason = model.params["reason"] as? String ?? "sessionChanged"
        let reason = String(rawReason.prefix(64))
        let targets: [STMiniWebView] = navigationController.viewControllers.compactMap { controller in
            if let h5Controller = controller as? STWebH5Crl,
               h5Controller.webView !== sourceWebView {
                return h5Controller.webView
            }
            if let miniController = controller as? STWebMiniprogramCrl,
               miniController.webView !== sourceWebView {
                return miniController.webView
            }
            return nil
        }

        DispatchQueue.main.async {
            // Online `/web` pages run in a separate WKWebView and retain the
            // browser's legacy localStorage. The host may explicitly opt in
            // an origin/key allow-list; only then mirror its selected session
            // keys and reload the online page from that updated snapshot.
            STWebApiManager.mirrorSessionToLegacyWebStorage(targets: targets)
            targets.forEach { webView in
                STWebApiManager.sendScriptMessageWithMethod(
                    "miniSessionChanged",
                    params: ["reason": reason],
                    webview: webView
                )
            }
        }
        return ["code": "1", "data": ["notified": targets.count]]
    }

    private static func mirrorSessionToLegacyWebStorage(targets: [STMiniWebView]) {
        guard let mirror = StminiFlutterPlugin.bridgeContextSnapshot["legacyWebStorageMirror"] as? [String: Any],
              let origins = mirror["origins"] as? [String],
              let rawKeys = mirror["keys"] as? [String],
              !origins.isEmpty,
              !rawKeys.isEmpty else {
            return
        }

        let allowedOrigins = Set(origins.compactMap { raw -> String? in
            guard let url = URL(string: raw),
                  let scheme = url.scheme?.lowercased(),
                  let host = url.host?.lowercased(),
                  ["http", "https"].contains(scheme) else {
                return nil
            }
            return "\(scheme)://\(host)"
        })
        let keys = Array(Set(rawKeys.filter { !$0.isEmpty && $0.count <= 128 })).sorted()
        guard !allowedOrigins.isEmpty, !keys.isEmpty else { return }

        let authStorageKey = (mirror["storageKey"] as? String)
            ?? (StminiFlutterPlugin.bridgeContextSnapshot["authStorageKey"] as? String)
        guard let authStorageKey,
              let stored = UserDefaults.standard.string(forKey: authStorageKey),
              let data = stored.data(using: .utf8),
              let snapshot = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        var values: [String: Any] = [:]
        keys.forEach { key in
            values[key] = snapshot[key] ?? NSNull()
        }

        // A remote PWA restores Pinia before any page-activation hook runs.
        // The host may opt in selected cache entries with the same strict
        // origin allow-list as auth keys. This component never assumes a
        // product cache key or storage namespace on its own.
        if let cacheStorageKey = mirror["cacheStorageKey"] as? String,
           let rawCacheKeys = mirror["cacheKeys"] as? [String],
           let cached = UserDefaults.standard.string(forKey: cacheStorageKey),
           let cacheData = cached.data(using: .utf8),
           let cacheSnapshot = try? JSONSerialization.jsonObject(with: cacheData) as? [String: Any] {
            let cacheKeys = Set(rawCacheKeys.filter { !$0.isEmpty && $0.count <= 128 })
            cacheKeys.forEach { key in
                values[key] = cacheSnapshot[key] ?? NSNull()
            }
        }

        guard let payload = jsonString(["values": values]) else { return }
        let script = """
        (() => {
          const values = \(payload).values || {};
          Object.keys(values).forEach((key) => {
            const value = values[key];
            if (value === null || value === undefined || value === '')
              window.localStorage.removeItem(key);
            else
              window.localStorage.setItem(key, String(value));
          });
          return true;
        })();
        """
        let reloadOnChange = (mirror["reloadOnChange"] as? Bool) ?? true

        targets.forEach { webView in
            guard let currentURL = webView.url,
                  let scheme = currentURL.scheme?.lowercased(),
                  let host = currentURL.host?.lowercased(),
                  allowedOrigins.contains("\(scheme)://\(host)") else {
                return
            }
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    STProjectHelper.Log("Mini 会话镜像写入旧 Web 存储失败：\(error.localizedDescription)")
                    return
                }
                let hostName = currentURL.host ?? ""
                STProjectHelper.Log("Mini 会话镜像已同步至旧 Web 存储：\(hostName)")
                if reloadOnChange {
                    webView.reload()
                }
            }
        }
    }
    
    
    static func callBack<T>(_ params: [String: Any], model: T) where T: STWebApiForm {
        var resultDic = params
        resultDic["method"] = model.method
        // Keep the same callback contract as the host-provided API handler.
        // Without methodId the Mini's bridge cannot resolve this response and
        // waits for its 15-second timeout.  This was most visible during
        // startup: mini_getMiniProgramContinuousKeepAlive completed natively but
        // blocked the first H5 render behind the timeout.
        resultDic["methodId"] = model.methodId
        guard let result = jsonString(resultDic) else {
            STProjectHelper.Log("api<\(model.method)>回调已取消：无法构造安全 JSON")
            return
        }
        STProjectHelper.Log(callbackLogSummary(resultDic, method: model.method, methodId: model.methodId))
        model.webview?.evaluateJavaScript("if (typeof window.CMSJsCallBack === 'function') { window.CMSJsCallBack(\(result)); true; } else { false; }") { (info, error) in
            if error != nil {
                STProjectHelper.Log("api<\(model.method)>回调失败 错误：\(String(describing: error?.localizedDescription))")
            } else if (info as? Bool) == false {
                STProjectHelper.Log("api<\(model.method)>回调暂未投递：H5 Bridge 尚未就绪")
            } else {
                STProjectHelper.Log(callbackLogSummary(resultDic, method: model.method, methodId: model.methodId))
            }
        }
    }
    
}
