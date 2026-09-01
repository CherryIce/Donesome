







import UIKit


@objc open class STWebMiniprogramCrl: STViewController, STWebCrlProtocol {
    
    public var webView: STMiniWebView!
    
    public var config: STWebConfig!
    
    public var name: String! = ""
    /// Stable package identity for host-side adapters.  Expose an explicit
    /// Objective-C bridge instead of relying on KVC for Swift-only `name`.
    @objc public var miniProgramId: String {
        return STWebResourceManager.miniNameHandle(name: name).0 ?? ""
    }
    fileprivate var isShow: Bool = false
    public var isChild: Bool = false
    /// The process lifecycle belongs to the one Mini root currently shown by
    /// the host, not to every retained WebView in the keep-alive pool.  A
    /// child page keeps its root selected so its underlying Mini runtime still
    /// receives the host event while the child is on top.
    private static weak var currentHostMiniRoot: STWebMiniprogramCrl?
    
    fileprivate var interactive: STWebTransInteractive!
    
    fileprivate lazy var transAnimation: STWebTransAnimation = {
        let trans = STWebTransAnimation(transType: .present)
        trans.completion = { [weak self] transType, succeeded in
            self?.handleTransitionCompletion(type: transType, succeeded: succeeded)
        }
        return trans
    }()
    
    fileprivate var loadAnimationView: STWebMiniLoadAnimate?
    /// An online Mini must let its native loading layer reach the first frame
    /// before it starts package resolution/download. Starting work from
    /// `viewDidLoad` races a modal presentation (notably from Flutter) and
    /// can leave users looking at a blank white controller while the ZIP is
    /// already transferring.
    private var hasStartedInitialOnlinePackageLoad = false
    private var directMiniPackageDownloadTask: URLSessionDownloadTask?
    /// Marks the one cold launch created by a forced self-update. The internal
    /// config flag is cleared as soon as the verified package is selected so
    /// later manual re-entry does not trigger another forced download.
    private var forcedSelfUpdateLaunch = false
    /// Only a self-managed forced update supplies an explicit native retry.
    /// Its source URL is not necessarily present in the original Grid link.
    private var onlineLoadingRetryAction: (() -> Void)?
    /// Set only by the capsule's explicit refresh action.  A normal close or
    /// interactive dismissal remains eligible for keep-alive.
    fileprivate var skipsKeepAliveOnNextDismiss = false
    /// Version of the package that this WebView actually loaded.  The keep-
    /// alive pool compares it with disk before reusing the runtime so a newly
    /// installed package is always picked up on the next cold launch.
    private(set) var loadedMiniPackageVersion: String?
    /// A retained Mini program must only be resumed after its first document
    /// has completed and while WKWebView's content process is still alive.
    /// iOS may terminate a background Web Content process; presenting that
    /// retained WebView again otherwise results in a permanent white page.
    private(set) var isKeepAliveRuntimeUsable = false
    /// The Web Content process may be killed while this controller is still
    /// visible. Reuse is no longer safe, but retain a one-shot notification
    /// so the cold-loaded Mini can explain the recovery after it renders.
    private var isRecoveringTerminatedWebContentProcess = false
    private static let terminatedProcessToastKeyPrefix = "STMini.TerminatedWebContentProcessToast."
    /// WebKit can defer `webViewWebContentProcessDidTerminate` until the next
    /// interaction after the App wakes. Track the background transition and
    /// probe the visible Mini after a short grace period. A probe timeout is
    /// not proof that the Web Content process died: iOS can still be restoring
    /// a healthy WebView, so only WebKit's real termination callback starts a
    /// cold recovery and shows the termination notice.
    private var backgroundEnteredAt: Date?
    private var lastBackgroundDurationMs = 0
    private var foregroundProcessProbeID: UUID?
    private static let foregroundProcessProbeInitialDelay: TimeInterval = 1.5
    private static let foregroundProcessProbeTimeout: TimeInterval = 1.2
    private static let foregroundProcessProbeRetryDelay: TimeInterval = 0.35
    private static let foregroundProcessProbeMaxAttempts = 2

    private enum DirectMiniDownloadBehavior: Equatable {
        case openAfterInstall
        case silentUpdate
    }
    
    fileprivate var capsuleBar: STWebMiniprogramCapsuleBar!
    
    fileprivate lazy var titleLbl: UILabel = {
        let lbl  = UILabel.init(frame: CGRectMake(0, 0, 200, 40))
        lbl.textAlignment = .center;
        lbl.backgroundColor = .clear;
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textColor = .black
        return lbl
    }()
    open override var title: String? {
        get {
            return self.titleLbl.text
        }
        set {
            self.titleLbl.text = newValue
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                STWebApiManager.sendScriptMessageWithMethod("darkModeChanged", params: [:], webview: webView)
            }
        }
    }
    
    @objc public init(name: String!, config: STWebConfig!, isChild: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.name = name
        self.config = config
        self.isChild = isChild
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserInfo(_:)),
            name: Notification.Name(STWebPersonalHandle.sharedInstance().noti_updateUserInfo),
            object: nil
        )
        // Login state and the selected trading account both change the scope
        // of a Quant Mini session.  The Mini must fail closed immediately,
        // rather than keep workers alive until its periodic session refresh.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(quantSessionDidChange(_:)),
            // STLoginSuccessNotification from the host notification contract.
            name: Notification.Name("kSTLoginSuccessNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(quantSessionDidChange(_:)),
            // STMini is a standalone Pod and cannot import the host's
            // STCore symbol directly; this is STChangeAccountSuccessNotification.
            name: Notification.Name("kSTChangeAccountSuccessNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(quantSessionDidChange(_:)),
            // STLogoutSuccessNotification from the host notification contract.
            name: Notification.Name("kSTLogoutSuccessNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hostLocaleDidChange(_:)),
            // STLanguageDidChangedNotification from the host notification contract.
            name: Notification.Name("kCmsLanguageDidChangedNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        navigationItem.titleView = titleLbl
        
        
        webView = STMiniWebView(frame: .zero, bindCrl: self)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        if config.webMode == .online {
            if shouldShowTabbar() {
                NSLayoutConstraint.activate([
                    webView.topAnchor.constraint(equalTo: view.topAnchor),
                    webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            }
            else {
                NSLayoutConstraint.activate([
                    webView.topAnchor.constraint(equalTo: view.topAnchor),
                    webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        }
        else {
            if shouldShowNavigationBar() {
                if shouldShowTabbar() {
                    NSLayoutConstraint.activate([
                        webView.topAnchor.constraint(equalTo: view.topAnchor, constant: STScreenHelper.ST_navigationFullHeight()),
                        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                    ])
                }
                else {
                    NSLayoutConstraint.activate([
                        webView.topAnchor.constraint(equalTo: view.topAnchor, constant: STScreenHelper.ST_navigationFullHeight()),
                        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
            }
            else {
                if shouldShowTabbar() {
                    NSLayoutConstraint.activate([
                        webView.topAnchor.constraint(equalTo: view.topAnchor),
                        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                    ])
                }
                else {
                    NSLayoutConstraint.activate([
                        webView.topAnchor.constraint(equalTo: view.topAnchor),
                        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
            }
        }
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        self.edgesForExtendedLayout = .all
        self.extendedLayoutIncludesOpaqueBars = true
        
        
        let (miniName, _) = STWebResourceManager.miniNameHandle(name: name)
        // Never expose an uninitialized white WebView for a Mini's first
        // page. This one native loading layer covers local-file loading,
        // version checks, downloads and the first H5 document load; it is
        // removed only when `webviewDidFinish` is received.
        if !isChild, let miniId = miniName, !miniId.isEmpty {
            beginOnlineMiniLoading(miniId: miniId)
        }
        if config.webMode != .online {
            
            
            let (miniPath, toPath) = STWebResourceManager.localMiniProgramPath(name: name)
            if miniPath!.count > 0 {
                let baseURL = URL(string: miniPath!)!
                let toURL = URL(string: toPath!)!
                
                if let path = config.path, !path.isEmpty {
                    
                    var fragment = path
                    
                    
                    if let params = config.params, !params.isEmpty {
                        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
                        fragment += "?" + queryString
                    }
                    
                    
                    if var components = URLComponents(string: miniPath!) {
                        components.fragment = fragment
                        if let finalURL = components.url {
                            STProjectHelper.Log("使用WebConfig拼接的URL: \(finalURL.absoluteString)")
                            webView.loadFileURL(finalURL, allowingReadAccessTo: toURL)
                        } else {
                            
                            let fallbackURLString = miniPath! + "#" + fragment
                            if let fallbackURL = URL(string: fallbackURLString) {
                                webView.loadFileURL(fallbackURL, allowingReadAccessTo: toURL)
                            } else {
                                webView.loadFileURL(baseURL, allowingReadAccessTo: toURL)
                            }
                        }
                    }
                } else {
                    
                    webView.loadFileURL(baseURL, allowingReadAccessTo: toURL)
                }
            } else {
                STProjectHelper.Log("本地小程序\(miniName!)找不到 \n 路径：\(miniPath!)")
                if !isChild {
                    finishOnlineLoading(message: "小程序本地包不存在")
                }
            }
        }
        
        if config.webMode == .online || shouldPresentAsMiniProgram() {
            refreshRootMiniChrome()
        } else {
            
            if shouldShowNavigationBar() {
                view.addSubview(naviView)
                naviView.backgroundColor = STWebCommonConfig.sharedInstance().naviBarColor
                addNaviBtn(image: STWebResourceManager.imageNamed(name: "back"), position: .left, action: #selector(back))
            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        STWebMiniProgramKeepAliveStore.shared.remove(self)
        isShow = true
        if !isChild {
            Self.currentHostMiniRoot = self
        }
        STWebApiManager.sendScriptMessageWithMethod("pageWillAppear", params: [:], webview: webView)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startInitialOnlinePackageLoadIfNeeded()
        // STMini's original full-screen interactive dismissal is owned by
        // the first page. Nested mini pages remain normal navigation pushes.
        installRootInteractiveDismissalIfNeeded()

    }

    private func startInitialOnlinePackageLoadIfNeeded() {
        guard !isChild,
              config.webMode == .online,
              !hasStartedInitialOnlinePackageLoad else {
            return
        }
        hasStartedInitialOnlinePackageLoad = true
        // The presentation has completed, so the loading ring/name have been
        // rendered before URLSession, verification and unpacking begin.
        DispatchQueue.main.async { [weak self] in
            self?.loadOnlineMiniPackage()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShow = false
        STWebApiManager.sendScriptMessageWithMethod("pageWillDisAppear", params: [:], webview: webView)
        if !isChild,
           (isBeingDismissed || navigationController?.isBeingDismissed == true),
           Self.currentHostMiniRoot === self {
            Self.currentHostMiniRoot = nil
        }
        if !isChild,
           (isBeingDismissed || navigationController?.isBeingDismissed == true),
           !(navigationController is STWebNavigationController) {
            cacheForKeepAliveAfterDismissal()
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // A normal close, forced re-entry, or an unusable runtime can bypass
        // the cache branch below.  In all cases a detached root must stop
        // being the recipient of App foreground/background events.
        clearCurrentHostMiniRootIfNeeded()

        // Capsule close, the first-page edge gesture and custom presentation
        // transitions do not all deliver the same `isBeingDismissed` state at
        // `viewWillDisappear`. Once the root Mini is genuinely detached from
        // its presentation, cache it from this common final lifecycle point.
        guard !isChild,
              !skipsKeepAliveOnNextDismiss,
              let rootNavigationController = navigationController as? STWebNavigationController,
              rootNavigationController.presentingViewController == nil,
              rootNavigationController.view.window == nil else {
            return
        }
        STWebMiniProgramKeepAliveStore.shared.cache(self,
                                                     navigationController: rootNavigationController)
    }
    
    deinit {
        if Self.currentHostMiniRoot === self {
            Self.currentHostMiniRoot = nil
        }
        NotificationCenter.default.removeObserver(self)
        
        
        STWebApiManager.sendScriptMessageWithMethod("document.documentElement.remove()", params:[:], webview: webView)
        STProjectHelper.Log("crl释放")
        
        
        webView?.cleanup()
        webView?.removeFromSuperview()
        webView = nil
    }
    
    
    
    
    private func shouldShowNavigationBar() -> Bool {
        
        if let params = config.params,
           let isNeedNavigationBar = params["isNeedNavigationBar"] {
            
            
            let lowercased = isNeedNavigationBar.lowercased()
            return lowercased == "1" || lowercased == "true" || lowercased == "yes"
        }
        
        
        return false
    }
    
    
    private func shouldShowTabbar() -> Bool {
        
        if let params = config.params {
            if let isOnTabbar = params["isOnTabbar"] {
                
                let stringValue: String
                if let str = isOnTabbar as? String {
                    stringValue = str
                } else if let num = isOnTabbar as? NSNumber {
                    
                    if CFGetTypeID(num) == CFBooleanGetTypeID() {
                        stringValue = num.boolValue ? "1" : "0"
                    } else {
                        stringValue = num.stringValue
                    }
                } else {
                    stringValue = String(describing: isOnTabbar)
                }
                
                
                let lowercased = stringValue.lowercased()
                return lowercased == "1" || lowercased == "true" || lowercased == "yes"
            }
        }
        
        
        return false
    }

    private func shouldPresentAsMiniProgram() -> Bool {
        guard let value = config.params?["presentAsMiniProgram"]?.lowercased() else {
            return false
        }
        return value == "1" || value == "true" || value == "yes"
    }

    /// `ishome` is a package-owned, root-only policy.  It is deliberately not
    /// read from `config.params`: Grid/QR links are untrusted presentation
    /// metadata and must not change close behaviour.
    private func isHomeMiniProgram() -> Bool {
        STWebResourceManager.miniPackageIsHome(name: name)
    }

    private func refreshRootMiniChrome() {
        guard !isChild,
              (config.webMode == .online || shouldPresentAsMiniProgram()) else { return }
        // A first online launch has no verified manifest until the download
        // completes. Keep the loader clean and create normal chrome only once
        // a package was selected.
        if config.webMode == .online,
           !STWebResourceManager.isInstalledMiniPackageUsable(name: name) {
            capsuleBar?.removeFromSuperview()
            return
        }
        if isHomeMiniProgram() {
            interactive?.invalidate()
            interactive = nil
            capsuleBar?.removeFromSuperview()
            STProjectHelper.Log("小程序<\(miniProgramId)>启用 ishome，隐藏根页胶囊并禁用侧滑关闭")
        } else {
            initialCapsuleBar()
        }
    }

    private func installRootInteractiveDismissalIfNeeded() {
        guard !isChild,
              navigationController?.viewControllers.first === self,
              interactive == nil,
              (config.webMode != .online || STWebResourceManager.isInstalledMiniPackageUsable(name: name)),
              !isHomeMiniProgram() else {
            return
        }
        interactive = STWebTransInteractive(target: self)
    }

    private func loadOnlineMiniPackage() {
        guard let miniName = STWebResourceManager.miniNameHandle(name: name).0 else {
            STProjectHelper.Log("小程序标识无效")
            return
        }

        let installedVersion = STWebResourceManager.installedMiniPackageVersion(name: miniName)
        let currentVersion = miniParameter("currentVersion")
        let minSupportVersion = miniParameter("minSupportVersion")
        let downloadURL = miniParameter("downloadUrl")
        let forcedSelfUpdate = miniParameter("__st_force_self_update") == "1"

        if let downloadURL, !isValidHTTPURL(downloadURL) {
            beginOnlineMiniLoading(miniId: miniName)
            finishOnlineLoading(message: "小程序下载地址无效")
            return
        }
        if let iconURL = miniParameter("iconUrl"), !isValidHTTPURL(iconURL) {
            beginOnlineMiniLoading(miniId: miniName)
            finishOnlineLoading(message: "小程序图标地址无效")
            return
        }

        // A forced self-update always starts in a newly presented Mini
        // controller. Do not reuse a retained runtime or apply the regular
        // Grid/QR version shortcuts: this launch must show the native loader
        // and complete its verified download before the package starts.
        if forcedSelfUpdate {
            forcedSelfUpdateLaunch = true
            STProjectHelper.Log("[DirectMini] forced update container launched miniId=\(miniName)")
            guard let downloadURL = downloadURL else {
                finishOnlineLoading(message: "小程序未提供下载地址")
                return
            }
            onlineLoadingRetryAction = { [weak self] in
                self?.loadOnlineMiniPackage()
            }
            beginOnlineMiniLoading(miniId: miniName)
            updateLoadAnimationIdentity(miniId: miniName, useInstalledPresentation: true)
            downloadDirectMiniPackage(
                name: miniName,
                downloadURL: downloadURL,
                minimumVersion: nil,
                behavior: .openAfterInstall,
                fallbackToInstalledPackage: false,
                requiresNewerVersion: true
            )
            return
        }

        // Migrate packages installed before launchLink was persisted. Only a
        // link that carries update information may replace the saved source;
        // a generated Home mini://id must never erase that information.
        if installedVersion != nil,
           currentVersion != nil || minSupportVersion != nil || downloadURL != nil,
           let sourceLink = config.sourceLink {
            STWebResourceManager.rememberInstalledMiniPackageLaunchLink(name: miniName, launchLink: sourceLink)
        }

        // CMS Grid items and QR payloads both use mini:// with the same
        // optional version fields. A verified local package at or above the
        // declared current version opens immediately and does no network I/O.
        if let currentVersion = currentVersion,
           let installedVersion = installedVersion,
           STWebResourceManager.compareMiniPackageVersion(installedVersion, currentVersion) >= 0 {
            STProjectHelper.Log("小程序<\(miniName)>本地版本 \(installedVersion) 已满足当前版本 \(currentVersion)，直接打开")
            openOnlineMiniPackage()
            return
        }

        // A compatible older package may start immediately. Its replacement
        // downloads in the background and becomes active on the next launch.
        if let currentVersion = currentVersion,
           let minSupportVersion = minSupportVersion,
           let installedVersion = installedVersion,
           STWebResourceManager.compareMiniPackageVersion(installedVersion, minSupportVersion) >= 0 {
            STProjectHelper.Log("小程序<\(miniName)>本地版本 \(installedVersion) 兼容，先打开并静默更新至 \(currentVersion)")
            openOnlineMiniPackage()
            if let downloadURL = downloadURL {
                downloadDirectMiniPackage(
                    name: miniName,
                    downloadURL: downloadURL,
                    minimumVersion: currentVersion,
                    behavior: .silentUpdate,
                    fallbackToInstalledPackage: false
                )
            } else {
                STProjectHelper.Log("小程序<\(miniName)>缺少 downloadUrl，跳过静默更新")
            }
            return
        }

        if let downloadURL = downloadURL {
            // No package, or a package below minSupportVersion: installation
            // must complete before this launch can continue.
            beginOnlineMiniLoading(miniId: miniName)
            downloadDirectMiniPackage(
                name: miniName,
                downloadURL: downloadURL,
                minimumVersion: currentVersion,
                behavior: .openAfterInstall,
                fallbackToInstalledPackage: currentVersion == nil
            )
            return
        }

        // The home entry generated from an already installed package has no
        // remote descriptor. It intentionally opens that validated package
        // directly instead of showing a loading failure.
        if installedVersion != nil {
            STProjectHelper.Log("小程序<\(miniName)>未提供更新链接，打开已校验本地包")
            openOnlineMiniPackage()
            return
        }

        beginOnlineMiniLoading(miniId: miniName)
        finishOnlineLoading(message: "小程序未提供下载地址")
    }

    private func miniParameter(_ key: String) -> String? {
        guard let value = config.params?[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private func isValidHTTPURL(_ value: String) -> Bool {
        guard let url = URL(string: value) else { return false }
        return isValidHTTPURL(url)
    }

    private func isValidHTTPURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty else {
            return false
        }
        return true
    }

    /// Handles a package update requested by the currently running Mini.
    /// The caller can supply a URL but can never select another miniId or pass
    /// a version: the active controller and downloaded verified manifest are
    /// authoritative. `isForce` is the only behavioural switch: forced
    /// updates cover the current WebView with the native loading view and only
    /// resume after the downloaded package has passed validation and loaded.
    func requestSelfManagedPackageUpdate(downloadURL: String, isForce: Bool) -> [String: Any] {
        guard !isChild,
              config.webMode == .online,
              let miniId = STWebResourceManager.miniNameHandle(name: name).0,
              !miniId.isEmpty else {
            return ["code": "0", "data": ["msg": "仅在线首层小程序可更新"]]
        }
        guard let url = URL(string: downloadURL), isValidHTTPURL(url) else {
            return ["code": "0", "data": ["msg": "小程序下载地址无效"]]
        }
        // Keep the source for a native retry and for a later keep-alive
        // re-entry. This is runtime metadata only; installed package identity
        // and channel still come from the verified manifest.
        var parameters = config.params ?? [:]
        parameters["downloadUrl"] = url.absoluteString
        config.params = parameters

        if isForce {
            // Strong updates deliberately close the whole current Mini
            // instance. It must not enter the keep-alive pool: the newly
            // created controller owns the initial-style native loading page
            // and cold-starts the verified package after installation.
            STProjectHelper.Log("[DirectMini] self update forced close miniId=\(miniId)")
            skipsKeepAliveOnNextDismiss = true
            STWebMiniProgramKeepAliveStore.shared.remove(self)
            var restartParameters = config.params ?? [:]
            restartParameters["downloadUrl"] = url.absoluteString
            restartParameters["__st_force_self_update"] = "1"
            config.params = restartParameters
            let infoStorage = STWebInfoStorage.sharedInstance()
            infoStorage.config = config
            infoStorage.name = name
            dismiss(animated: false) {
                STWebOpenHandler.reOpenMiniprogram(animated: false)
            }
            return ["code": "1", "data": ["accepted": true, "isforce": "1"]]
        }
        STProjectHelper.Log("[DirectMini] self update silent miniId=\(miniId)")
        downloadDirectMiniPackage(
            name: miniId,
            downloadURL: url.absoluteString,
            minimumVersion: nil,
            behavior: .silentUpdate,
            fallbackToInstalledPackage: false,
            requiresNewerVersion: false
        )
        return ["code": "1", "data": ["accepted": true, "isforce": "0"]]
    }

    /// Loading starts before the mini package is available, so the host must
    /// select the display name directly from the unified mini:// link. The
    /// App language, not the device region, decides whether miniNameEn wins.
    private func isCurrentAppLanguageChinese() -> Bool {
        let savedLanguage = UserDefaults.standard.string(forKey: "STLanguageCode") ?? ""
        let language = (savedLanguage.isEmpty ? (Locale.preferredLanguages.first ?? "") : savedLanguage)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return language == "zh" || language.hasPrefix("zh-") || language.hasPrefix("zh_")
    }

    private func suppliedLoadingMiniName() -> String? {
        if !isCurrentAppLanguageChinese(), let englishName = miniParameter("miniNameEn") {
            return englishName
        }
        return miniParameter("miniName")
    }

    private func beginOnlineMiniLoading(miniId: String) {
        guard loadAnimationView == nil else { return }
        let loadingAnimation = initialLoadAnimationView()
        let loadingView = loadingAnimation as! UIView
        loadingView.frame = view.bounds
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // This screen represents a Mini runtime handoff, not a translucent
        // progress hint. It must conceal the outgoing H5 and its dialogs.
        loadingView.backgroundColor = .systemBackground
        loadingView.isOpaque = true
        loadAnimationView = loadingAnimation
        view.addSubview(loadingView)
        view.bringSubviewToFront(loadingView)
        updateLoadAnimationIdentity(miniId: miniId)
        loadRemoteLoadAnimationIcon(miniId: miniId)
    }

    private func downloadDirectMiniPackage(
        name: String,
        downloadURL: String,
        minimumVersion: String?,
        behavior: DirectMiniDownloadBehavior,
        fallbackToInstalledPackage: Bool,
        requiresNewerVersion: Bool = false,
        attempt: Int = 0,
        deadline: Date = Date().addingTimeInterval(15)
    ) {
        let remainingTimeout = deadline.timeIntervalSinceNow
        guard remainingTimeout > 0 else {
            retryDirectMiniPackageDownloadIfNeeded(name: name, downloadURL: downloadURL, minimumVersion: minimumVersion, behavior: behavior, fallbackToInstalledPackage: fallbackToInstalledPackage, requiresNewerVersion: requiresNewerVersion, attempt: attempt, deadline: deadline, failureMessage: "小程序下载超时，请检查网络后重试")
            return
        }
        guard let url = URL(string: downloadURL), isValidHTTPURL(url) else {
            finishOnlineLoading(message: "小程序下载地址无效")
            return
        }
        let port = url.port.map { ":\($0)" } ?? ""
        let logURL = "\(url.scheme ?? "")://\(url.host ?? "")\(port)\(url.path)"
        STProjectHelper.Log("[DirectMini] download start miniId=\(name) attempt=\(attempt + 1) url=\(logURL) timeout=12s")
        DispatchQueue.main.async { [weak self] in
            // DNS/TLS/response headers may take a moment before the first
            // byte callback. Keep the spinner alive during that gap;
            // `didWriteData` switches to real progress immediately.
            self?.loadAnimationView?.beginPostDownloadProcessing()
        }

        // Follow the existing iOS download pattern: URLSession gives us a
        // real temporary file URL, which must be copied immediately before
        // its completion handler returns. Do not route direct ZIP packages
        // through Tiercel's URL-keyed cache: retrying one URL with a new file
        // name otherwise reuses an old completed task without such a file.
        directMiniPackageDownloadTask?.cancel()
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = min(12, remainingTimeout)
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        // An unavailable LAN server must resolve into the existing retry and
        // error UI, not leave the native loading layer spinning indefinitely.
        sessionConfiguration.waitsForConnectivity = false
        sessionConfiguration.timeoutIntervalForRequest = min(12, remainingTimeout)
        sessionConfiguration.timeoutIntervalForResource = remainingTimeout
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        directMiniPackageDownloadTask = session.downloadTask(with: request) { [weak self] temporaryURL, response, error in
            guard let self = self else { return }
            guard error == nil,
                  let temporaryURL = temporaryURL,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                let nsError = error as NSError?
                let failure = error?.localizedDescription ?? "HTTP \(statusCode.map { String($0) } ?? "无响应")"
                STProjectHelper.Log("[DirectMini] download failed miniId=\(name) attempt=\(attempt + 1) url=\(logURL) status=\(statusCode.map { String($0) } ?? "nil") errorDomain=\(nsError?.domain ?? "nil") errorCode=\(nsError.map { String($0.code) } ?? "nil") error=\(failure)")
                self.retryDirectMiniPackageDownloadIfNeeded(name: name, downloadURL: downloadURL, minimumVersion: minimumVersion, behavior: behavior, fallbackToInstalledPackage: fallbackToInstalledPackage, requiresNewerVersion: requiresNewerVersion, attempt: attempt, deadline: deadline, failureMessage: self.directMiniDownloadFailureMessage(statusCode: statusCode, error: error))
                return
            }

            guard Date() < deadline else {
                self.retryDirectMiniPackageDownloadIfNeeded(name: name, downloadURL: downloadURL, minimumVersion: minimumVersion, behavior: behavior, fallbackToInstalledPackage: fallbackToInstalledPackage, requiresNewerVersion: requiresNewerVersion, attempt: attempt, deadline: deadline, failureMessage: "小程序下载超时，请检查网络后重试")
                return
            }

            let temporarySize = ((try? FileManager.default.attributesOfItem(atPath: temporaryURL.path)[.size]) as? NSNumber)?.int64Value ?? -1
            STProjectHelper.Log("[DirectMini] download response miniId=\(name) attempt=\(attempt + 1) status=\(httpResponse.statusCode) expectedBytes=\(httpResponse.expectedContentLength) temporaryBytes=\(temporarySize)")

            let archiveURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(name)-scan-\(UUID().uuidString).zip")
            DispatchQueue.main.async {
                self.loadAnimationView?.beginPostDownloadProcessing()
            }
            do {
                try? FileManager.default.removeItem(at: archiveURL)
                try FileManager.default.copyItem(at: temporaryURL, to: archiveURL)
            } catch {
                let nsError = error as NSError
                STProjectHelper.Log("[DirectMini] temporary copy failed miniId=\(name) attempt=\(attempt + 1) source=\(temporaryURL.lastPathComponent) errorDomain=\(nsError.domain) errorCode=\(nsError.code) error=\(error.localizedDescription)")
                self.retryDirectMiniPackageDownloadIfNeeded(name: name, downloadURL: downloadURL, minimumVersion: minimumVersion, behavior: behavior, fallbackToInstalledPackage: fallbackToInstalledPackage, requiresNewerVersion: requiresNewerVersion, attempt: attempt, deadline: deadline, failureMessage: "小程序下载失败，请稍后重试")
                return
            }

            guard Date() < deadline else {
                try? FileManager.default.removeItem(at: archiveURL)
                self.retryDirectMiniPackageDownloadIfNeeded(name: name, downloadURL: downloadURL, minimumVersion: minimumVersion, behavior: behavior, fallbackToInstalledPackage: fallbackToInstalledPackage, requiresNewerVersion: requiresNewerVersion, attempt: attempt, deadline: deadline, failureMessage: "小程序下载超时，请检查网络后重试")
                return
            }

            let archiveSize = ((try? FileManager.default.attributesOfItem(atPath: archiveURL.path)[.size]) as? NSNumber)?.int64Value ?? -1
            STProjectHelper.Log("[DirectMini] archive ready miniId=\(name) attempt=\(attempt + 1) archiveBytes=\(archiveSize)")

            STWebResourceManager.installDirectMiniPackage(archivePath: archiveURL.path, name: name, minimumVersion: minimumVersion, requiresNewerVersion: requiresNewerVersion, launchLink: self.config.sourceLink) { [weak self] result in
                guard let self = self else { return }
                self.directMiniPackageDownloadTask = nil
                switch result {
                case .success(let outcome):
                    switch outcome {
                    case .installed(let version):
                        STProjectHelper.Log("[DirectMini] install succeeded miniId=\(name) version=\(version) attempt=\(attempt + 1)")
                    case .keptInstalled(let version):
                        STProjectHelper.Log("[DirectMini] install skipped miniId=\(name) reason=downloaded_version_not_newer retainedVersion=\(version) attempt=\(attempt + 1)")
                    }
                    if behavior == .openAfterInstall {
                        self.updateLoadAnimationIdentity(miniId: name, useInstalledPresentation: true)
                        self.openOnlineMiniPackage()
                    } else {
                        switch outcome {
                        case .installed(let version):
                            STProjectHelper.Log("[DirectMini] silent update completed miniId=\(name) version=\(version)")
                        case .keptInstalled(let version):
                            STProjectHelper.Log("[DirectMini] silent update skipped miniId=\(name) reason=downloaded_version_not_newer retainedVersion=\(version)")
                        }
                    }
                case .failure(let error):
                    let nsError = error as NSError
                    STProjectHelper.Log("[DirectMini] install failed miniId=\(name) attempt=\(attempt + 1) errorDomain=\(nsError.domain) errorCode=\(nsError.code) error=\(error.localizedDescription)")
                    if behavior == .openAfterInstall {
                        // The old package remains atomically intact on disk,
                        // but a forced launch must not silently reopen it when
                        // the server supplied an older archive.
                        let message = requiresNewerVersion && nsError.code == 11
                            ? "强更版本不符"
                            : "小程序安装失败：\(error.localizedDescription)"
                        self.finishOnlineLoading(message: message)
                    }
                }
            }
        }
        directMiniPackageDownloadTask?.resume()
    }

    /// A LAN QR may be opened while the device is still establishing its first
    /// connection to the local server. Retry that transport step once before
    /// showing an error; package validation/install errors must never retry or
    /// fall back because they indicate a real package problem.
    private func retryDirectMiniPackageDownloadIfNeeded(
        name: String,
        downloadURL: String,
        minimumVersion: String?,
        behavior: DirectMiniDownloadBehavior,
        fallbackToInstalledPackage: Bool,
        requiresNewerVersion: Bool,
        attempt: Int,
        deadline: Date,
        failureMessage: String
    ) {
        DispatchQueue.main.async {
            self.directMiniPackageDownloadTask = nil
            guard attempt == 0, deadline.timeIntervalSinceNow > 0 else {
                STProjectHelper.Log("[DirectMini] retry exhausted miniId=\(name)")
                if behavior == .silentUpdate {
                    STProjectHelper.Log("[DirectMini] silent update failed miniId=\(name)，保留当前本地包")
                } else if fallbackToInstalledPackage {
                    self.openInstalledMiniPackageOrShowDownloadFailure(name: name)
                } else {
                    self.finishOnlineLoading(message: failureMessage)
                }
                return
            }
            STProjectHelper.Log("[DirectMini] retry scheduled miniId=\(name) delayMs=600")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.downloadDirectMiniPackage(name: name, downloadURL: downloadURL, minimumVersion: minimumVersion, behavior: behavior, fallbackToInstalledPackage: fallbackToInstalledPackage, requiresNewerVersion: requiresNewerVersion, attempt: attempt + 1, deadline: deadline)
            }
        }
    }

    private func directMiniDownloadFailureMessage(statusCode: Int?, error: Error?) -> String {
        if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorTimedOut {
            return "小程序下载超时，请检查网络后重试"
        }
        if statusCode != nil {
            return "小程序下载失败，请稍后重试"
        }
        return "小程序下载失败，请检查网络后重试"
    }

    /// A QR may be temporarily unreachable after this mini program has
    /// already been installed. Download failure is not an integrity failure,
    /// so a previously verified package remains a safe fallback. Archives
    /// that did download but fail manifest/install validation never use this
    /// path and are still reported as installation failures.
    private func openInstalledMiniPackageOrShowDownloadFailure(name: String) {
        directMiniPackageDownloadTask = nil
        if STWebResourceManager.isInstalledMiniPackageUsable(name: name) {
            STProjectHelper.Log("小程序<\(name)>下载失败，打开已校验的本地包")
            openOnlineMiniPackage()
        } else {
            finishOnlineLoading(message: "小程序下载失败")
        }
    }

    private func updateLoadAnimationIdentity(miniId: String, fallbackName: String? = nil, useInstalledPresentation: Bool = false) {
        let suppliedName = suppliedLoadingMiniName()
        let hasSuppliedName = suppliedName != nil
        let hasSuppliedIcon = !(config.params?["iconUrl"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        // The QR's own name/icon take precedence. Only an ID-only QR may use
        // a locally verified package as its initial presentation.
        let useLocalPresentation = useInstalledPresentation ||
            (!hasSuppliedName && !hasSuppliedIcon && STWebResourceManager.isInstalledMiniPackageUsable(name: miniId))
        let installedName = useLocalPresentation
            ? STWebResourceManager.installedMiniPackagePreferredDisplayName(
                name: miniId,
                preferEnglish: !isCurrentAppLanguageChinese()
            )
            : nil
        let displayName = suppliedName ?? installedName ?? fallbackName
        let icon = useLocalPresentation
            ? STWebResourceManager.installedMiniPackageIconURL(name: miniId).flatMap { UIImage(contentsOfFile: $0.path) }
            : nil
        loadAnimationView?.updateMiniIdentity(miniId, miniName: displayName, icon: icon)
    }

    private func loadRemoteLoadAnimationIcon(miniId: String) {
        guard let iconURLString = config.params?["iconUrl"],
              let iconURL = URL(string: iconURLString),
              isValidHTTPURL(iconURL) else {
            return
        }
        URLSession.shared.dataTask(with: iconURL) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                let displayName = self.suppliedLoadingMiniName()
                self.loadAnimationView?.updateMiniIdentity(miniId, miniName: displayName, icon: image)
            }
        }.resume()
    }

    private func openOnlineMiniPackage() {
        guard let entry = STWebResourceManager.installedMiniPackageEntry(name: name) else {
            finishOnlineLoading(message: "小程序本地包未通过完整性校验")
            return
        }
        guard let url = STWebResourceManager.installedMiniPackageRootURL(name: name, entry: entry) else {
            finishOnlineLoading(message: "小程序本地入口无效")
            return
        }
        loadedMiniPackageVersion = STWebResourceManager.installedMiniPackageVersion(name: name)
        config.params?.removeValue(forKey: "__st_force_self_update")
        refreshRootMiniChrome()
        installRootInteractiveDismissalIfNeeded()
        webView.load(URLRequest(url: url))
    }

    private func finishOnlineLoading(message: String) {
        STProjectHelper.Log(message)
        loadAnimationView?.finished()
        loadAnimationView = nil
        let retryAction = onlineLoadingRetryAction
        onlineLoadingRetryAction = nil

        // 在线包失败时以前只移除了加载动画，容器会呈现空白页。
        // 明确反馈原因并允许原地重试，避免扫码安装时看起来像“打开成功但白屏”。
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "小程序打开失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel) { [weak self] _ in
            self?.close()
        })
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            if let retryAction = retryAction {
                retryAction()
            } else {
                self?.loadOnlineMiniPackage()
            }
        })
        present(alert, animated: true)
    }

    
}


extension STWebMiniprogramCrl {

    /// A retained Mini remains alive in a transparent host view so its
    /// strategies can continue. Tell H5 that it is not visible, allowing it
    /// to keep workers but stop expensive full-page rendering until reuse.
    func setKeepAliveRuntimeHidden(_ hidden: Bool) {
        sendHostMessage("hostMiniRuntimeVisibilityChanged", params: ["hidden": hidden])
        if hidden {
            // A later background interval is measured from its own lifecycle
            // boundary, not from an earlier visible App resume.
            lastBackgroundDurationMs = 0
            return
        }
        // Hidden runtimes intentionally do not receive appShow when the App
        // itself returns. Send it only after this specific Mini becomes
        // visible again, carrying the interval used to fence stale ticks.
        let backgroundDurationMs = lastBackgroundDurationMs
        lastBackgroundDurationMs = 0
        // `sendHostMessage` queues the visibility bridge dispatch on main.
        // Queue appShow behind it so H5 always observes visible=true first.
        DispatchQueue.main.async { [weak self] in
            self?.sendHostLifecycleMessage("appShow", params: [
                "backgroundDurationMs": max(0, backgroundDurationMs),
                "recoveryMode": "memory_resume",
            ])
        }
    }

    /// Called by STMini's keep-alive store for roots that are not the current
    /// visible Mini. This preserves the existing one-visible-root rule while
    /// still providing the system-background persistence boundary.
    func notifyHostApplicationHiddenWhileRetained() {
        guard isKeepAliveRuntimeUsable else { return }
        sendHostLifecycleMessage("appHide")
        STProjectHelper.Log("[STMini][Lifecycle] appHide delivered retained miniId=\(miniProgramId)")
    }

    /// Re-entry from STMini's keep-alive cache.  The existing document is not
    /// reloaded, so strategy workers and the current tab keep running.  The
    /// newest link metadata is still remembered and its default update check
    /// runs silently in the background.
    func prepareForKeepAliveReuse(config: STWebConfig) {
        self.config = config
        refreshOnlineMiniPackageInBackgroundIfNeeded()
    }

    /// STWebNavigationController invokes this after a successful dismissal so
    /// a pushed STMini child page can be retained with the Mini root. The
    /// explicit capsule re-enter action marks this runtime as non-reusable.
    func cacheForKeepAliveAfterDismissal() {
        guard !isChild, !skipsKeepAliveOnNextDismiss else { return }
        STWebMiniProgramKeepAliveStore.shared.cache(self)
    }

    private func refreshOnlineMiniPackageInBackgroundIfNeeded() {
        guard config.webMode == .online,
              let miniId = STWebResourceManager.miniNameHandle(name: name).0,
              let downloadURL = miniParameter("downloadUrl") else {
            return
        }
        let installedVersion = STWebResourceManager.installedMiniPackageVersion(name: miniId)
        let currentVersion = miniParameter("currentVersion")
        if let currentVersion = currentVersion,
           let installedVersion = installedVersion,
           STWebResourceManager.compareMiniPackageVersion(installedVersion, currentVersion) >= 0 {
            return
        }
        STProjectHelper.Log("小程序<\(miniId)>保活重开，后台检查更新")
        downloadDirectMiniPackage(name: miniId,
                                  downloadURL: downloadURL,
                                  minimumVersion: currentVersion,
                                  behavior: .silentUpdate,
                                  fallbackToInstalledPackage: false)
    }

    @objc private func updateUserInfo(_: Notification) {
        sendHostMessage("updateUserInfo", params: [:])
        // A profile refresh is not necessarily a login or trading-account
        // boundary. Keep a retained Quant Mini running and refresh only its
        // display here. Real login/logout/account-switch notifications above
        // are routed through quantSessionDidChange instead.
    }

    @objc private func quantSessionDidChange(_: Notification) {
        sendHostMessage("hostQuantSessionChanged", params: [:])
    }

    @objc private func hostLocaleDidChange(_ notification: Notification) {
        sendHostMessage("hostLocaleChanged", params: ["locale": hostLocaleCode()])
    }

    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        backgroundEnteredAt = Date()
        let miniId = miniProgramId
        let continuousKeepAlive = STWebMiniProgramKeepAliveStore.shared.isContinuousKeepAliveEnabled(miniId: miniId)
        STProjectHelper.Log("[STMini][Lifecycle] app_background miniId=\(miniId) visible=\(isShow) runtimeUsable=\(isKeepAliveRuntimeUsable) continuousKeepAlive=\(continuousKeepAlive)")
    }

    /// `willResignActive` is intentionally used instead of waiting for
    /// `didEnterBackground`: WebKit still has a short runnable window here to
    /// flush state before iOS suspends it.  The static root guard prevents
    /// cached Mini WebViews from receiving a foreground/background event that
    /// belongs to another, currently visible Mini.
    @objc private func applicationWillResignActive(_ notification: Notification) {
        guard Self.currentHostMiniRoot === self else { return }
        sendHostLifecycleMessage("appHide")
        STProjectHelper.Log("[STMini][Lifecycle] appHide delivered miniId=\(miniProgramId)")
    }

    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        let backgroundDuration = backgroundEnteredAt.map { Date().timeIntervalSince($0) } ?? 0
        lastBackgroundDurationMs = max(0, Int(backgroundDuration * 1000))
        backgroundEnteredAt = nil
        if Self.currentHostMiniRoot === self {
            sendHostLifecycleMessage("appShow", params: [
                "backgroundDurationMs": lastBackgroundDurationMs,
                "recoveryMode": "visible_resume",
            ])
            STProjectHelper.Log("[STMini][Lifecycle] appShow delivered miniId=\(miniProgramId)")
        }
        let miniId = miniProgramId
        let continuousKeepAlive = STWebMiniProgramKeepAliveStore.shared.isContinuousKeepAliveEnabled(miniId: miniId)
        let willProbe = backgroundDuration >= 1 && isShow && isKeepAliveRuntimeUsable && !isRecoveringTerminatedWebContentProcess
        STProjectHelper.Log("[STMini][Lifecycle] app_foreground miniId=\(miniId) backgroundDurationMs=\(Int(backgroundDuration * 1000)) visible=\(isShow) runtimeUsable=\(isKeepAliveRuntimeUsable) continuousKeepAlive=\(continuousKeepAlive) willProbe=\(willProbe)")
        // Ignore short Control Center / permission interruptions. The probe is
        // for a resumed, already-rendered Mini after a genuine background stay.
        guard backgroundDuration >= 1,
              isShow,
              isKeepAliveRuntimeUsable,
              !isRecoveringTerminatedWebContentProcess else {
            return
        }
        // A foregrounded WebView may need more than one run-loop turn before
        // JavaScript can execute. Do not turn an immediate readyState timeout
        // into a false "content process terminated" recovery.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.foregroundProcessProbeInitialDelay) { [weak self] in
            guard let self = self,
                  self.isShow,
                  self.isKeepAliveRuntimeUsable,
                  !self.isRecoveringTerminatedWebContentProcess else {
                return
            }
            self.probeWebContentProcessAfterForeground()
        }
    }

    private func sendHostMessage(_ method: String, params: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let webView = self.webView,
                  self.isShow || self.isKeepAliveRuntimeUsable else { return }
            // Keep-alive may retain the root behind an internal Mini page or
            // after dismissal. It still owns the Quant runtime, so account
            // and locale invalidations must reach it before it is shown again.
            STWebApiManager.sendScriptMessageWithMethod(method, params: params, webview: webView)
        }
    }

    /// App lifecycle is delivered while UIKit may be about to suspend the
    /// process. Unlike ordinary UI notifications, do not insert an extra main
    /// queue turn when we already run on main, otherwise `appHide` can miss
    /// the last runnable window before WebKit is frozen.
    private func sendHostLifecycleMessage(_ method: String, params: [String: Any] = [:]) {
        let send = { [weak self] in
            guard let self = self,
                  let webView = self.webView,
                  self.isShow || self.isKeepAliveRuntimeUsable else { return }
            STWebApiManager.sendScriptMessageWithMethod(method, params: params, webview: webView)
        }
        if Thread.isMainThread {
            send()
        } else {
            DispatchQueue.main.async(execute: send)
        }
    }

    private func clearCurrentHostMiniRootIfNeeded() {
        guard !isChild,
              Self.currentHostMiniRoot === self,
              let navigationController = navigationController as? STWebNavigationController,
              navigationController.presentingViewController == nil,
              navigationController.view.window == nil else {
            return
        }
        Self.currentHostMiniRoot = nil
    }

    private func hostLocaleCode() -> String {
        let savedLanguage = UserDefaults.standard.string(forKey: "STLanguageCode") ?? ""
        let sourceLanguage = savedLanguage.isEmpty ? (Locale.preferredLanguages.first ?? "") : savedLanguage
        let language = sourceLanguage
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if language.hasPrefix("zh") {
            return language.contains("hant") || language.contains("tw") || language.contains("hk") || language.contains("mo") ? "zh-Hant" : "zh-Hans"
        }
        return language.isEmpty ? "en-US" : sourceLanguage
    }

}


extension STWebMiniprogramCrl {
    
    
    public func webviewDidFinish() {
        isKeepAliveRuntimeUsable = true
        isRecoveringTerminatedWebContentProcess = false
        if forcedSelfUpdateLaunch {
            forcedSelfUpdateLaunch = false
            let renderedVersion = loadedMiniPackageVersion ?? "unknown"
            STProjectHelper.Log("[DirectMini] forced update package rendered miniId=\(miniProgramId) version=\(renderedVersion)")
        }
        loadAnimationView?.finished()
        showTerminatedProcessRecoveryToastIfNeeded()
        showMemoryWarningRecoveryToastIfNeeded()
    }

    /// Called by STMiniWebView when WKWebView loses its Web Content process.
    /// Do not leave the current controller displaying an unusable WebView:
    /// remove it from keep-alive immediately and cold-load the installed Mini.
    public func webviewContentProcessDidTerminate() {
        guard !isRecoveringTerminatedWebContentProcess else { return }
        foregroundProcessProbeID = nil
        isRecoveringTerminatedWebContentProcess = true
        isKeepAliveRuntimeUsable = false
        let miniId = miniProgramId
        UserDefaults.standard.set(true, forKey: Self.terminatedProcessToastKeyPrefix + miniId)
        let wasCachedForKeepAlive = STWebMiniProgramKeepAliveStore.shared.discardTerminated(self)
        STProjectHelper.Log("小程序<\(miniId)>Web 内容进程已终止，已移出保活缓存并冷启动恢复")

        // A detached cache entry is discarded here; the next user opening
        // constructs a new controller. A visible controller has no cache
        // entry, so reload it now instead of leaving a white page onscreen.
        guard !wasCachedForKeepAlive else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reloadAfterWebContentProcessTermination()
        }
    }

    private func reloadAfterWebContentProcessTermination() {
        guard webView != nil else { return }
        // Online Minis always load the verified on-disk package, so this is a
        // true cold document load rather than a reload of a dead process.
        if config.webMode == .online {
            beginOnlineMiniLoading(miniId: miniProgramId)
            openOnlineMiniPackage()
        } else {
            // Preserve the established local-Mini loading path while still
            // forcing WKWebView to create a new Web Content process.
            webView.reload()
        }
    }

    /// A terminated Web Content process is not guaranteed to invoke its
    /// delegate immediately after the device wakes. An evaluateJavaScript
    /// round-trip is cheap for a healthy document. WebKit can be briefly busy
    /// while restoring after sleep, so probe failures remain non-fatal and
    /// are retried later. A real delegate termination remains authoritative.
    private func probeWebContentProcessAfterForeground(attempt: Int = 1) {
        guard webView != nil, !isRecoveringTerminatedWebContentProcess else { return }
        let probeID = UUID()
        foregroundProcessProbeID = probeID
        webView.evaluateJavaScript("document.readyState") { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self = self, self.foregroundProcessProbeID == probeID else { return }
                self.foregroundProcessProbeID = nil
                if error != nil {
                    self.retryForegroundProcessProbeOrRecover(attempt: attempt, reason: "失败")
                } else {
                    STProjectHelper.Log("[STMini][Lifecycle] foreground_probe_success miniId=\(self.miniProgramId) attempt=\(attempt)")
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.foregroundProcessProbeTimeout) { [weak self] in
            guard let self = self,
                  self.foregroundProcessProbeID == probeID,
                  self.isShow,
                  !self.isRecoveringTerminatedWebContentProcess else {
                return
            }
            self.foregroundProcessProbeID = nil
            self.retryForegroundProcessProbeOrRecover(attempt: attempt, reason: "超时")
        }
    }

    private func retryForegroundProcessProbeOrRecover(attempt: Int, reason: String) {
        guard isShow, isKeepAliveRuntimeUsable, !isRecoveringTerminatedWebContentProcess else { return }
        if attempt < Self.foregroundProcessProbeMaxAttempts {
            STProjectHelper.Log("小程序<\(miniProgramId)>前台探测\(reason)，短暂等待后重试 \(attempt + 1)/\(Self.foregroundProcessProbeMaxAttempts)")
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.foregroundProcessProbeRetryDelay) { [weak self] in
                guard let self = self,
                      self.isShow,
                      self.isKeepAliveRuntimeUsable,
                      !self.isRecoveringTerminatedWebContentProcess else { return }
                self.probeWebContentProcessAfterForeground(attempt: attempt + 1)
            }
            return
        }
        // A failed readiness probe is not evidence that WebKit terminated.
        // Cap this foreground pass at two probes and wait for a real WebKit
        // termination callback (or the next foreground transition) instead
        // of scheduling a permanent 3-second polling loop.
        STProjectHelper.Log("小程序<\(miniProgramId)>前台探测\(reason)且重试失败，本次恢复不再探测；等待 WebKit 真实终止回调或下次前台恢复")
    }

    private func showTerminatedProcessRecoveryToastIfNeeded() {
        let key = Self.terminatedProcessToastKeyPrefix + miniProgramId
        guard UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.removeObject(forKey: key)
        let message = "小程序运行进程已被系统终止，已重新加载"
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let webView = self.webView else { return }
            if let apiHandle = STWebPersonalHandle.sharedInstance().apiHandle {
                _ = apiHandle(["method": "showToast", "params": ["title": message, "duration": 2]], webView)
            } else {
                STProjectHelper.Log("小程序<\(self.miniProgramId)>恢复提示未显示：宿主未提供 Toast handler")
            }
        }
    }

    private func showMemoryWarningRecoveryToastIfNeeded() {
        guard STWebMiniProgramKeepAliveStore.shared.consumeMemoryWarningRecoveryNotice(miniId: miniProgramId) else { return }
        let message = "小程序后台运行实例已因内存压力释放，已重新加载"
        if let apiHandle = STWebPersonalHandle.sharedInstance().apiHandle,
           let webView = webView {
            _ = apiHandle(["method": "showToast", "params": ["title": message, "duration": 2]], webView)
        } else {
            STProjectHelper.Log("小程序<\(miniProgramId)>内存压力恢复提示未显示：宿主未提供 Toast handler")
        }
    }
    
    
    public func close() {
        // UIKit may clear `self.navigationController` while completing a
        // custom dismissal. Capture the root navigation container before the
        // transition so a continuous Mini can always be placed in STMini's
        // keep-alive store afterwards.
        let rootNavigationController = navigationController as? STWebNavigationController
        dismiss(animated: true) { [self, rootNavigationController] in
            // Capsule close is the main path back to the host. Do not rely
            // solely on UINavigationController's dismissal callback here:
            // custom presentations may skip that callback. Cache explicitly
            // after the transition, when the navigation hierarchy is detached.
            guard !isChild, !skipsKeepAliveOnNextDismiss else { return }
            STWebMiniProgramKeepAliveStore.shared.cache(self,
                                                         navigationController: rootNavigationController)
        }
    }

}


extension STWebMiniprogramCrl: STWebMiniprogramCapsuleBarDelegate {
    
    
    func initialCapsuleBar() {
        if (capsuleBar == nil) {
            capsuleBar = STWebMiniprogramCapsuleBar(frame: CGRectMake(view.ST_right - ST_CapsuleBarRightGap - ST_CapsuleBarItemWidth*2, STScreenHelper.ST_statusBarHeight() + (STScreenHelper.ST_navigationBarHeight() - ST_CapsuleBarItemHeight)/2, ST_CapsuleBarItemWidth*2, ST_CapsuleBarItemHeight))
            capsuleBar.delegate = self
            view.addSubview(capsuleBar)
        }
    }
    
    
    func changeCapsuleBar(isShowStandIn: Bool) {
        // Transition-finished is a process-wide notification. Controllers
        // created for child/loading Mini routes do not own a capsule bar, so
        // touching the implicitly-unwrapped outlet here used to terminate the
        // host with a Swift fatal error after a scanned Mini package opened.
        guard !isHomeMiniProgram(), let capsuleBar = capsuleBar else {
            return
        }
        capsuleBar.removeFromSuperview()
        if isShowStandIn {
            view.addSubview(capsuleBar)
        }
        else {
            STScreenHelper.keyWindow().addSubview(capsuleBar)
        }
    }
    
    
    func more() {
        let toolView = STWebToolView.init(frame: CGRectMake(0, 0, view.ST_width, 200), items: [["title": "重新进入小程序", "imgStr": "tool_shuaxin", "key": "reEnter"]])
        let popConfig = HLPopConfig()
        popConfig.popBackColor = .ST_hex("#E8E8E8")
        popConfig.cornerRadius = 10
        popConfig.corner = [UIRectCorner.topLeft,UIRectCorner.topRight]
        HLPopViewController().showBottomPopView(toolView, config: popConfig) { [weak self] info, isCancel in
            if isCancel != true {
                if info["key"] != nil {
                    
                    let key = info["key"] as! String
                    STProjectHelper.Log("toolView点击-\(key)")
                    if key == "reEnter" {
                        // Explicit "re-enter" is a refresh action, not a
                        // warm resume.  Drop this runtime before presenting
                        // the new root Mini program.
                        if let self = self {
                            self.skipsKeepAliveOnNextDismiss = true
                            STWebMiniProgramKeepAliveStore.shared.remove(self)
                        }
                        let infoStorage = STWebInfoStorage.sharedInstance()
                        infoStorage.config = self?.config
                        infoStorage.name = self?.name
                        self?.dismiss(animated: true, completion: {
                            STWebOpenHandler.reOpenMiniprogram()
                        })
                    }
                }
            }
        }
    }
    
    
    func initialLoadAnimationView() -> STWebMiniLoadAnimate {
        return STWebMiniLoadAnimationView(frame: view.bounds)
    }
    
    @objc func back(){
        if(navigationController?.children[0] == self){
            close()
            return;
        }
        navigationController?.popViewController(animated: true)
    }
    
}


extension STWebMiniprogramCrl: URLSessionDownloadDelegate {
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard downloadTask == directMiniPackageDownloadTask,
              totalBytesExpectedToWrite > 0 else { return }
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async { [weak self] in
            self?.loadAnimationView?.setDownloadProgress(progress)
        }
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // The task's completion handler owns the temporary-file copy and the
        // install transaction. This delegate hook only supplies byte progress.
    }
}

extension STWebMiniprogramCrl: UIViewControllerTransitioningDelegate {
    
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transAnimation.transType = .present
        return transAnimation
    }

    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        changeCapsuleBar(isShowStandIn: true)
        transAnimation.transType = .dismiss
        transAnimation.interactive = interactive
        return transAnimation
    }

    
    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive?.isInteractive == true ? interactive : nil
    }
    
}


extension STWebMiniprogramCrl {

    /// The capsule belongs to a visible Mini only. After a successful close
    /// it must not remain attached to the host window; a cancelled gesture
    /// restores it because the Mini is still on screen.
    fileprivate func handleTransitionCompletion(type: STWebTransType, succeeded: Bool) {
        switch type {
        case .present:
            changeCapsuleBar(isShowStandIn: false)
        case .dismiss:
            if succeeded {
                capsuleBar?.removeFromSuperview()
            } else {
                changeCapsuleBar(isShowStandIn: false)
            }
        }
    }
}
