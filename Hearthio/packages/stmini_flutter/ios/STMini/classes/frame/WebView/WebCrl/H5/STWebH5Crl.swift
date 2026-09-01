






import UIKit
import WebKit


@objc open class STWebH5Crl: STViewController, STWebCrlProtocol {
    
    public var webView: STMiniWebView!
    
    public var config: STWebConfig!
    fileprivate var isShow: Bool = false
    public var url: String!
    public var isChild: Bool = false
    /// Set by Mini-owned local navigation or intercepted Mini `open /web`.
    /// A pushed page carrying this marker is part of the owning Mini
    /// navigation stack, so it may use the same generic STMini APIs as the
    /// root page. Ordinary `/web` pages keep the default false value.
    @objc public var isMiniInternalPage: Bool = false
    /// True only for the package-owned child pushed after an online `/web`
    /// page requests an in-package route such as `/login`.
    @objc public var isMiniRouteChild: Bool = false
    fileprivate var progressView : UIProgressView?
    fileprivate var observation: NSKeyValueObservation?
    /// Ordinary H5 pages are never eligible for Mini keep-alive.  Release the
    /// WebKit runtime as soon as the controller actually leaves its navigation
    /// stack instead of waiting for `deinit`: WebKit may otherwise keep its
    /// scroll view/process alive long enough for the debug leak detector to
    /// report the already-popped page.
    private var hasReleasedWebRuntime = false
    /// A WKWebView content process can be reclaimed while this controller is
    /// still on top of a Mini navigation stack.  Keep recovery local to the
    /// affected page; the root Mini may still have a healthy strategy runtime.
    private var isRecoveringTerminatedWebContentProcess = false
    private var terminatedWebContentProcessRecoveryCount = 0
    private var lastTerminatedWebContentProcessRecoveryAt: Date?
    private var terminatedWebContentProcessRecoveryToken: UUID?
    private static let terminatedWebContentProcessRecoveryWindow: TimeInterval = 60
    private static let terminatedWebContentProcessRecoveryTimeout: TimeInterval = 12
    /// A first network authorization prompt can fail WKWebView's provisional
    /// request before it has a history item. Retry the full URL at most once
    /// automatically; a visible manual action remains available afterwards.
    private var hasNavigationFailure = false
    private var hasAttemptedAutomaticNavigationRecovery = false
    private var automaticNavigationRecoveryToken: UUID?
    private static let automaticNavigationRecoveryDelay: TimeInterval = 0.35
    /// UIKit may reset `isMovingFromParent` by `viewDidDisappear`. Capture the
    /// terminal transition in `viewWillDisappear` so parent-owned H5 pages
    /// are still released after their containing controller is popped.
    @objc public private(set) var shouldReleaseWebRuntimeAfterDisappear = false
    /// Do not use STViewController.naviView here. Its frame-based button is
    /// created before this full-screen Mini child has a final width, which
    /// can leave the back affordance outside the rendered header.
    fileprivate let h5HeaderView = UIView()
    fileprivate let h5BackButton = UIButton(type: .custom)
    fileprivate let h5BackImageView = UIImageView()
    fileprivate lazy var h5TitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private lazy var navigationErrorTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private lazy var navigationErrorMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private lazy var navigationRetryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }()
    private lazy var navigationErrorView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemBackground
        container.isHidden = true

        let stack = UIStackView(arrangedSubviews: [
            navigationErrorTitleLabel,
            navigationErrorMessageLabel,
            navigationRetryButton
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.setCustomSpacing(24, after: navigationErrorMessageLabel)
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32),
            navigationErrorTitleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            navigationErrorMessageLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        return container
    }()

    /// STViewController hides UINavigationController's bar and the H5
    /// container renders its own header. Keep the title in that visible
    /// header so both regular H5 and Mini-pushed H5 pages behave the same.
    open override var title: String? {
        get { h5TitleLabel.text }
        set { h5TitleLabel.text = newValue }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                STWebApiManager.sendScriptMessageWithMethod("darkModeChanged", params: [:], webview: webView)
            }
        }
    }
    
    /// Keep the historical Objective-C initializer available for ordinary
    /// host `/web` pages.
    @objc public init(url: String!, config: STWebConfig!, isChild: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
        self.config = config
        self.isChild = isChild
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserInfo(_:)),
            name: Notification.Name(STWebPersonalHandle.sharedInstance().noti_updateUserInfo),
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
        
        
        webView = STMiniWebView(frame: .zero, bindCrl: self)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        if shouldShowNavigationBar() {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor, constant: STScreenHelper.ST_navigationFullHeight()),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        self.edgesForExtendedLayout = .all
        self.extendedLayoutIncludesOpaqueBars = true
            
        loadPageFromOriginalURL()
            
        
        view.backgroundColor = .white
        
        
        if shouldShowNavigationBar() {
            h5HeaderView.translatesAutoresizingMaskIntoConstraints = false
            h5HeaderView.backgroundColor = STWebCommonConfig.sharedInstance().naviBarColor
            view.addSubview(h5HeaderView)

            h5BackButton.translatesAutoresizingMaskIntoConstraints = false
            h5BackButton.accessibilityLabel = "Back"
            h5BackButton.addTarget(self, action: #selector(STWebH5Crl.back), for: .touchUpInside)
            // Keep the button as the hit target. The visible image is an
            // independent UIImageView, exactly as the capsule/tool icons.
            h5BackImageView.translatesAutoresizingMaskIntoConstraints = false
            h5BackImageView.contentMode = .scaleAspectFit
            let backImage = STWebResourceManager.imageNamed(name: "back")
            h5BackImageView.image = backImage
            if backImage == nil {
                STProjectHelper.Log("STWebH5Crl 返回图标 back 未找到")
            }
            h5HeaderView.addSubview(h5BackImageView)
            h5HeaderView.addSubview(h5BackButton)

            h5HeaderView.addSubview(h5TitleLabel)
            NSLayoutConstraint.activate([
                h5HeaderView.topAnchor.constraint(equalTo: view.topAnchor),
                h5HeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                h5HeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                h5HeaderView.heightAnchor.constraint(equalToConstant: STScreenHelper.ST_navigationFullHeight()),
                h5BackButton.leadingAnchor.constraint(equalTo: h5HeaderView.leadingAnchor, constant: 6),
                h5BackButton.bottomAnchor.constraint(equalTo: h5HeaderView.bottomAnchor),
                h5BackButton.widthAnchor.constraint(equalToConstant: STScreenHelper.ST_navigationBarHeight()),
                h5BackButton.heightAnchor.constraint(equalToConstant: STScreenHelper.ST_navigationBarHeight()),
                h5BackImageView.centerXAnchor.constraint(equalTo: h5BackButton.centerXAnchor),
                h5BackImageView.centerYAnchor.constraint(equalTo: h5BackButton.centerYAnchor),
                h5BackImageView.widthAnchor.constraint(equalToConstant: 24),
                h5BackImageView.heightAnchor.constraint(equalToConstant: 24),
                h5TitleLabel.leadingAnchor.constraint(equalTo: h5BackButton.trailingAnchor, constant: 8),
                h5TitleLabel.trailingAnchor.constraint(equalTo: h5HeaderView.trailingAnchor, constant: -(STScreenHelper.ST_navigationBarHeight() + 8)),
                h5TitleLabel.bottomAnchor.constraint(equalTo: h5HeaderView.bottomAnchor),
                h5TitleLabel.heightAnchor.constraint(equalToConstant: STScreenHelper.ST_navigationBarHeight())
            ])
            
            if config.openSource == .h5 {
                
                
            }
        }

        view.addSubview(navigationErrorView)
        NSLayoutConstraint.activate([
            navigationErrorView.topAnchor.constraint(equalTo: webView.topAnchor),
            navigationErrorView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            navigationErrorView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            navigationErrorView.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
        
        
        
        
        
        
        
        
        
        
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldReleaseWebRuntimeAfterDisappear = false
        isShow = true
        STWebApiManager.sendScriptMessageWithMethod("pageWillAppear", params: [:], webview: webView)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scheduleAutomaticNavigationRecoveryIfPossible()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShow = false
        shouldReleaseWebRuntimeAfterDisappear = shouldReleaseWebRuntimeWhenDisappearing()
        // Preserve the existing H5 lifecycle contract for every disappearance,
        // including a hard pop/dismiss. The actual WebView teardown happens
        // after the transition completes in `viewDidDisappear`.
        STWebApiManager.sendScriptMessageWithMethod("pageWillDisAppear", params: [:], webview: webView)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Do not clean up merely because another controller was pushed above
        // this one: that page may still be returned to.  Cleanup is only for
        // a pop/dismiss (including dismissal of the containing navigation
        // controller), where this ordinary H5 page cannot be reused.
        if shouldReleaseWebRuntimeAfterDisappear || shouldReleaseWebRuntimeWhenDisappearing() {
            releaseWebRuntimeIfNeeded(reason: "controller_disappeared")
        }
    }
    
    func listView() -> UIView {
        return self.view
    }
    
    deinit {
        releaseWebRuntimeIfNeeded(reason: "controller_deinit")
        STProjectHelper.Log("crl释放")
    }

    private func releaseWebRuntimeIfNeeded(reason: String) {
        guard !hasReleasedWebRuntime else { return }
        hasReleasedWebRuntime = true

        NotificationCenter.default.removeObserver(self)
        observation = nil
        automaticNavigationRecoveryToken = nil

        // `STMiniWebView.cleanup()` stops loading, removes the JS bridge and
        // clears WebKit delegates before the controller is released.  Do not
        // evaluate JavaScript here: an asynchronous teardown callback can
        // prolong the lifetime of a page that has already been popped.
        let currentWebView = webView
        currentWebView?.cleanup()
        currentWebView?.removeFromSuperview()
        webView = nil
        STProjectHelper.Log("STWebH5Crl 退出并释放 WebView 运行时，原因: \(reason)")
    }

    private func isLeavingNavigationStack() -> Bool {
        isBeingDismissed ||
            isMovingFromParent ||
            navigationController?.isBeingDismissed == true ||
            navigationController?.isMovingFromParent == true ||
            parent?.isBeingDismissed == true ||
            parent?.isMovingFromParent == true
    }

    private func shouldReleaseWebRuntimeWhenDisappearing() -> Bool {
        if !isMiniInternalPage {
            return isLeavingNavigationStack()
        }

        // A Mini-owned H5 page is retained only when the root navigation
        // controller is cached as a whole.  If this child itself is popped,
        // it cannot be reused and must release independently.
        return isMovingFromParent
    }

    private func loadPageFromOriginalURL() {
        guard !hasReleasedWebRuntime,
              let pageURLString = url,
              let pageURL = URL(string: pageURLString),
              webView != nil else { return }
        if pageURL.isFileURL {
            webView.loadFileURL(pageURL, allowingReadAccessTo: pageURL.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: pageURL))
        }
    }

    private func navigationErrorCopy() -> (title: String, message: String, retry: String) {
        let urlLanguage = URLComponents(string: url ?? "")?.queryItems?
            .first(where: { $0.name.lowercased() == "lang" })?.value?.lowercased()
        let preferredLanguage = Locale.preferredLanguages.first?.lowercased()
        let usesChinese = (urlLanguage ?? preferredLanguage ?? "").hasPrefix("zh")
        if usesChinese {
            return (
                title: "暂时无法加载页面",
                message: "网络权限设置完成后会自动重试，你也可以手动重新加载。",
                retry: "重新加载"
            )
        }
        return (
            title: "Unable to Load Page",
            message: "The page will retry after network access is resolved. You can also reload it manually.",
            retry: "Reload"
        )
    }

    private func showNavigationFailure(_ error: NSError) {
        guard !hasReleasedWebRuntime, webView != nil else { return }
        hasNavigationFailure = true
        let copy = navigationErrorCopy()
        navigationErrorTitleLabel.text = copy.title
        navigationErrorMessageLabel.text = copy.message
        navigationRetryButton.setTitle(copy.retry, for: .normal)
        navigationRetryButton.accessibilityLabel = copy.retry
        navigationErrorView.isHidden = false
        view.bringSubviewToFront(navigationErrorView)
        if shouldShowNavigationBar() {
            view.bringSubviewToFront(h5HeaderView)
        }
        STProjectHelper.Log("STWebH5Crl 主文档加载失败 domain=\(error.domain) code=\(error.code)")
        scheduleAutomaticNavigationRecoveryIfPossible()
    }

    private func scheduleAutomaticNavigationRecoveryIfPossible() {
        guard hasNavigationFailure,
              isShow,
              !hasAttemptedAutomaticNavigationRecovery,
              UIApplication.shared.applicationState == .active else { return }
        hasAttemptedAutomaticNavigationRecovery = true
        let token = UUID()
        automaticNavigationRecoveryToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.automaticNavigationRecoveryDelay) { [weak self] in
            guard let self = self,
                  self.automaticNavigationRecoveryToken == token,
                  self.hasNavigationFailure else { return }
            guard self.isShow,
                  self.viewIfLoaded?.window != nil,
                  UIApplication.shared.applicationState == .active else {
                // The system permission sheet may have appeared after the
                // failure callback, or the page may still be presenting. Let
                // didBecomeActive/viewDidAppear schedule the retry instead.
                self.hasAttemptedAutomaticNavigationRecovery = false
                self.automaticNavigationRecoveryToken = nil
                return
            }
            self.retryFailedNavigation(source: "automatic")
        }
    }

    private func retryFailedNavigation(source: String) {
        guard !hasReleasedWebRuntime,
              hasNavigationFailure,
              webView != nil else { return }
        hasNavigationFailure = false
        automaticNavigationRecoveryToken = nil
        navigationErrorView.isHidden = true
        webView.stopLoading()
        STProjectHelper.Log("STWebH5Crl 重新加载完整页面 source=\(source)")
        loadPageFromOriginalURL()
    }

    @objc private func retryButtonTapped() {
        retryFailedNavigation(source: "manual")
    }
    
    
    
    
    private func shouldShowNavigationBar() -> Bool {
        
        if let params = config.params,
           let isNeedNavigationBar = params["isNeedNavigationBar"] {
            
            
            let lowercased = isNeedNavigationBar.lowercased()
            return lowercased == "1" || lowercased == "true" || lowercased == "yes"
        }
        
        
        return false
    }

}


extension STWebH5Crl {
    
    @objc private func updateUserInfo(_ notification: Notification) {
        if isShow {
            STWebApiManager.sendScriptMessageWithMethod("updateUserInfo", params: [:], webview: webView)
        }
    }

    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        scheduleAutomaticNavigationRecoveryIfPossible()
    }
    
}

extension STWebH5Crl {
    
    
    public func webviewDidFinish() {
        isRecoveringTerminatedWebContentProcess = false
        terminatedWebContentProcessRecoveryToken = nil
        hasNavigationFailure = false
        hasAttemptedAutomaticNavigationRecovery = false
        automaticNavigationRecoveryToken = nil
        navigationErrorView.isHidden = true
        progressView?.isHidden = true
    }

    public func webviewDidFail(_ error: NSError) {
        // WebKit reports cancellation when a redirect or a newer navigation
        // supersedes the current one. It is not a user-visible network error.
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return
        }
        showNavigationFailure(error)
    }

    /// This is also invoked for Mini-owned `open({ router: "/web" })` pages.
    /// Reload the exact approved page instead of leaving the dead WKWebView
    /// white.  Two terminations in a short window are treated as a bad page or
    /// an unrecoverable renderer loop and safely leave the affected page.
    public func webviewContentProcessDidTerminate() {
        guard !hasReleasedWebRuntime,
              webView != nil else { return }

        // A second system callback means the reload itself lost its content
        // process. It supersedes the pending timeout and consumes the second
        // recovery attempt instead of leaving a white page until that timeout.
        if isRecoveringTerminatedWebContentProcess {
            isRecoveringTerminatedWebContentProcess = false
            terminatedWebContentProcessRecoveryToken = nil
        }

        let now = Date()
        if let previous = lastTerminatedWebContentProcessRecoveryAt,
           now.timeIntervalSince(previous) > Self.terminatedWebContentProcessRecoveryWindow {
            terminatedWebContentProcessRecoveryCount = 0
        }
        lastTerminatedWebContentProcessRecoveryAt = now
        terminatedWebContentProcessRecoveryCount += 1

        guard terminatedWebContentProcessRecoveryCount <= 2 else {
            fallbackFromRepeatedWebContentTermination()
            return
        }

        isRecoveringTerminatedWebContentProcess = true
        let token = UUID()
        terminatedWebContentProcessRecoveryToken = token
        STProjectHelper.Log("STWebH5Crl Web 内容进程已终止，重载当前页面 attempt=\(terminatedWebContentProcessRecoveryCount)")
        webView.reload()

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.terminatedWebContentProcessRecoveryTimeout) { [weak self] in
            guard let self = self,
                  self.terminatedWebContentProcessRecoveryToken == token,
                  self.isRecoveringTerminatedWebContentProcess else { return }
            // `webViewDidFinish` did not arrive. Retry once through the same
            // bounded recovery path; the third failed attempt falls back.
            self.isRecoveringTerminatedWebContentProcess = false
            self.terminatedWebContentProcessRecoveryToken = nil
            self.webviewContentProcessDidTerminate()
        }
    }

    private func fallbackFromRepeatedWebContentTermination() {
        isRecoveringTerminatedWebContentProcess = false
        terminatedWebContentProcessRecoveryToken = nil
        let message: String
        if isMiniInternalPage {
            message = "页面恢复失败，已返回小程序首页"
            STProjectHelper.Log("STWebH5Crl Mini 二级页恢复失败，返回小程序首页")
        } else {
            message = "页面恢复失败，已返回上一页"
            STProjectHelper.Log("STWebH5Crl 普通 H5 页面恢复失败，返回上一页")
        }
        if let apiHandle = STWebPersonalHandle.sharedInstance().apiHandle,
           let webView = webView {
            _ = apiHandle(["method": "showToast", "params": ["title": message, "duration": 2]], webView)
        }
        if isMiniInternalPage {
            navigationController?.popViewController(animated: true)
        } else {
            back()
        }
    }
    
    public func close() {
        self.back()
    }
    
}


extension STWebH5Crl {
    
    @objc func back(){
        if(navigationController?.children[0] == self){
            dismiss(animated: true, completion:nil)
            return;
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc func more(){
        let toolView = STWebToolView.init(frame: CGRectMake(0, 0, view.ST_width, 200), items: [["title": "刷新", "imgStr": "tool_shuaxin", "key": "refresh"], ["title": "复制链接", "imgStr": "tool_lianjie", "key": "copy"]])
        let popConfig = HLPopConfig()
        popConfig.popBackColor = .ST_hex("#E8E8E8")
        popConfig.cornerRadius = 10
        popConfig.corner = [UIRectCorner.topLeft,UIRectCorner.topRight]
        HLPopViewController().showBottomPopView(toolView, config: popConfig) { [weak self] info, isCancel in
            if isCancel != true {
                if info["key"] != nil {
                    
                    let key = info["key"] as! String
                    STProjectHelper.Log("toolView点击-\(key)")
                    if key == "refresh" {
                        
                        self?.webView.reload()
                        
                        self?.progressView?.isHidden = false
                        self?.progressView?.progress = 0.05
                    }
                    else if key == "copy" {
                    }
                }
            }
        }
    }
    
}
