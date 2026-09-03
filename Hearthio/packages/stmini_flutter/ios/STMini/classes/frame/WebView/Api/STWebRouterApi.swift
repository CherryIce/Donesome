






import Foundation
import UIKit


struct STWebRouterApi {
    
    
    
    
    
    /// Opens a package-owned local page.  It is intentionally not an online
    /// H5 navigation API; online pages use the ordinary `open` API and are
    /// intercepted below when their caller belongs to an STMini stack.
    func navigateTo<T>(model: T) -> [String: Any] where T: STWebApiForm {
        guard let path = model.params["path"] as? String, !path.isEmpty else {
            STProjectHelper.Log("api<mini_navigateTo>path没有传")
            return failure("缺少 path")
        }
        guard let root = STWebApiManager.miniRootController(for: model.webview) else {
            return failure("mini_navigateTo 仅支持 STMini 小程序")
        }
        guard let localPage = STWebResourceManager.installedMiniPackageLocalPageURL(name: root.name, path: path) else {
            return failure("小程序本地页面无效")
        }
        guard let navigationController = model.webview?.bindCrl?.navigationController else {
            return failure("小程序导航容器不可用")
        }
        let title = model.params["title"] as? String
        DispatchQueue.main.async {
            var params = ["isNeedNavigationBar": "true"]
            if let title, !title.isEmpty {
                params["title"] = title
            }
            let config = STWebConfig(webMode: .local, params: params)
            config.openSource = .mini
            let controller = STWebH5Crl(url: localPage.absoluteString, config: config, isChild: true)
            controller.isMiniInternalPage = true
            if let title, !title.isEmpty {
                controller.title = title
            }
            navigationController.pushViewController(controller, animated: true)
        }
        return ["code": "1", "data": ["opened": true]]
    }

    /// Handles `open({ router: "/web", link })` before the host's ordinary
    /// router does.  The page is online, but its controller is part of the
    /// caller's Mini navigation stack and therefore preserves Mini identity.
    func openInternalWebIfNeeded<T>(model: T) -> [String: Any]? where T: STWebApiForm {
        guard model.method == "open", (model.params["router"] as? String) == "/web" else {
            return nil
        }
        // Full link is intentionally printed in the Debug console for this
        // integration investigation. It lets us distinguish an empty link,
        // an unexpanded relative path and a bad CMS URL before routing it.
        let debugRawLink = model.params["link"] as? String ?? "<empty>"
        Self.trace("received caller=\(String(describing: type(of: model.webview?.bindCrl))) linkRaw=\(debugRawLink)")
        guard let navigationController = model.webview?.bindCrl?.navigationController else {
            Self.trace("reject: navigation controller unavailable")
            return failure("小程序导航容器不可用")
        }
        guard let rawLink = model.params["link"] as? String,
              let link = Self.resolvedExternalWebURL(rawLink, relativeTo: model.webview?.url) else {
            Self.trace("reject: unsafe or empty link")
            return failure("仅支持安全的 HTTPS 页面")
        }
        let title = model.params["title"] as? String
        DispatchQueue.main.async {
            // This is an online page, but it is still owned by the Mini
            // navigation stack.  Navigation-bar visibility is an H5 choice:
            // when the parameter is absent, STMini keeps the Mini default
            // (hidden). H5 opts in only for pages that need native back
            // navigation, such as the external usage guide.
            var params = [String: String]()
            if let value = model.params["isNeedNavigationBar"] as? String {
                params["isNeedNavigationBar"] = value
            } else if let value = model.params["isNeedNavigationBar"] as? NSNumber {
                params["isNeedNavigationBar"] = value.stringValue
            }
            if let title, !title.isEmpty { params["title"] = title }
            let config = STWebConfig(webMode: .h5, params: params)
            config.openSource = .mini
            let controller = STWebH5Crl(url: link.absoluteString, config: config, isChild: true)
            // `/web` belongs to STMini for every STMini-hosted page. Keep
            // Mini-only API permissions separate from routing: only a caller
            // with a Mini root passes that identity to the new child page.
            controller.isMiniInternalPage = STWebApiManager.miniRootController(for: model.webview) != nil
            if let title, !title.isEmpty { controller.title = title }
            navigationController.pushViewController(controller, animated: true)
            Self.trace("pushed url=\(Self.safeLogURL(link.absoluteString)) stack=\(navigationController.viewControllers.count)")
        }
        return ["code": "1", "data": ["opened": true]]
    }

    /// A `/web` page is a separate native WebView, so its H5 JavaScript no
    /// longer has the Mini root as `window.parent`. Keep that page in the
    /// stack, then push a package-owned H5 child carrying the requested
    /// route. The child H5 resolves the route through its own Vue Router and
    /// a back action returns to the original `/web` page.
    func forwardMiniRouteOpenIfNeeded<T>(model: T) -> [String: Any]? where T: STWebApiForm {
        guard model.method == "open",
              let router = model.params["router"] as? String,
              !router.isEmpty,
              router != "/web",
              let caller = model.webview?.bindCrl as? STWebH5Crl,
              let navigationController = caller.navigationController,
              let miniRoot = navigationController.viewControllers.first(where: {
                  guard let controller = $0 as? STWebMiniprogramCrl else { return false }
                  return !controller.isChild
              }) as? STWebMiniprogramCrl else {
            return nil
        }

        var routeParams = model.params
        routeParams.removeValue(forKey: "methodId")
        // A login requested by an online `/web` is an authentication detour,
        // not a normal entry into the package profile page. The local H5
        // consumes this marker through its existing `isBack` contract and
        // pops this child back to the original `/web` after success.
        if router == "/login" || router == "/mine/login" {
            routeParams["isBack"] = "1"
        }
        guard JSONSerialization.isValidJSONObject(routeParams),
              let routeData = try? JSONSerialization.data(withJSONObject: routeParams),
              let localPage = STWebResourceManager.installedMiniPackageLocalPageURL(
                  name: miniRoot.name,
                  // `__mini_child` is also used by ordinary mini_navigateTo.
                  // Keep a distinct marker so H5 only closes the route child
                  // that was pushed from an online `/web` page.
                  path: "index.html#/?__mini_child=1&__mini_route_child=1&__mini_open_route=\(base64URL(routeData))"
              ) else {
            return failure("小程序路由页面无效")
        }

        Self.trace("push Mini route=\(router) without closing /web")
        DispatchQueue.main.async {
            // The routed H5 page (for example login) renders its own back
            // affordance. Showing a native header here produces two back
            // buttons and is inconsistent with regular Mini routes.
            let config = STWebConfig(webMode: .local, params: ["isNeedNavigationBar": "false"])
            config.openSource = .mini
            let controller = STWebH5Crl(url: localPage.absoluteString, config: config, isChild: true)
            controller.isMiniInternalPage = true
            controller.isMiniRouteChild = true
            navigationController.pushViewController(controller, animated: true)
        }
        return ["code": "1", "data": ["opened": true]]
    }

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func failure(_ message: String) -> [String: Any] {
        return ["code": "0", "data": ["msg": message]]
    }

    private static func isAllowedExternalWebURL(_ rawURL: String) -> Bool {
        guard let url = URL(string: rawURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.host != nil else {
            return false
        }
        if url.scheme?.lowercased() == "https" { return true }
        #if DEBUG
        return url.scheme?.lowercased() == "http"
        #else
        return false
        #endif
    }

    private static func resolvedExternalWebURL(_ rawURL: String, relativeTo baseURL: URL?) -> URL? {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let resolved = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL,
              isAllowedExternalWebURL(resolved.absoluteString) else {
            return nil
        }
        return resolved
    }

    private static func safeLogURL(_ rawURL: String?) -> String {
        guard let rawURL, let components = URLComponents(string: rawURL) else {
            return rawURL?.prefix(160).description ?? "<empty>"
        }
        var redacted = components
        redacted.query = nil
        redacted.fragment = nil
        return redacted.string ?? rawURL.prefix(160).description
    }

    private static func trace(_ message: String) {
        // STProjectHelper writes to the Xcode console only in DEBUG and
        // forwards the same transient event to an embedding Flutter host.
        // It does not persist a Release log on device.
        STProjectHelper.Log("[web-router] \(message)")
    }

    
}
