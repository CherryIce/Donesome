






import Foundation
@preconcurrency import WebKit

@objc public class STMiniWebView: WKWebView {
    
    @objc public var isChild: Bool = false
    @objc public var environment: STWebEnv = STWebEnv.normal
    
    @objc public weak var bindCrl: (STViewController&STWebCrlProtocol)?
    /// Root Mini-program controllers may be retained by STMini's LRU cache
    /// after a modal dismissal.  Detaching their hierarchy must not tear down
    /// the WebView bridge, otherwise the next presentation would be a blank,
    /// non-interactive WebView instead of a real warm start.
    @objc public var preserveRuntimeWhenDetached: Bool = false
    private var hasCleanedUp: Bool = false
    // WKUserContentController strongly retains its script-message handlers.  Keep
    // the handler separate from the web view so registering the bridge does not
    // create a WKWebView -> configuration -> handler -> WKWebView retain cycle.
    private var scriptMessageHandler: STWeakScriptMessageHandler?
    
    
    private lazy var loadingBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .large)
        } else {
            indicator = UIActivityIndicatorView(style: .gray)
        }
        indicator.color = .gray 
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    
    private lazy var loadingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true 
        return imageView
    }()
    
    
    @objc public convenience init(frame: CGRect, bindCrl: (STViewController&STWebCrlProtocol)?) {
        self.init(frame: frame, configuration: Self.stMiniWebViewConfiguration())
        self.bindCrl = bindCrl
    }

    private static func stMiniWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 11.0, *) {
            configuration.setURLSchemeHandler(
                STWebSchemeHandler.shared,
                forURLScheme: STWebResourceManager.installedMiniResourceScheme
            )
        }
        return configuration
    }
    
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        backgroundColor = .clear
        uiDelegate = self
        navigationDelegate = self
        
        initialWebViewConfiguration()
        
        setupLoadingViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupLoadingViews() {
        
        addSubview(loadingBackgroundView)
        addSubview(loadingImageView)
        addSubview(loadingIndicator)
        
        
        NSLayoutConstraint.activate([
            loadingBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            loadingBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        
        NSLayoutConstraint.activate([
            loadingImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    
    private func showLoadingIndicator() {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let personalHandle = STWebPersonalHandle.sharedInstance()
            
            
            self.loadingBackgroundView.isHidden = false
            self.bringSubviewToFront(self.loadingBackgroundView)
            
            if let loadingImg = personalHandle.loadingImg, !loadingImg.isEmpty {
                
                if let image = UIImage(named: loadingImg) {
                    self.loadingImageView.image = image
                    self.loadingImageView.isHidden = false
                    self.bringSubviewToFront(self.loadingImageView)
                    self.bringSubviewToFront(self.loadingIndicator)
                } else {
                    
                    self.loadingImageView.isHidden = true
                    self.loadingIndicator.startAnimating()
                    self.bringSubviewToFront(self.loadingIndicator)
                }
            } else {
                
                self.loadingImageView.isHidden = true
                self.loadingIndicator.startAnimating()
                self.bringSubviewToFront(self.loadingIndicator)
            }
        }
    }
    
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            self.loadingImageView.isHidden = true
            self.loadingBackgroundView.isHidden = true
        }
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if (newSuperview == nil && !preserveRuntimeWhenDetached) {
            cleanup()
        } else {
            
            hideLoadingIndicator()
        }
    }
    
    
    func initialWebViewConfiguration() {
        configuration.preferences.setValue(true, forKey:"allowFileAccessFromFileURLs")
        let handler = STWeakScriptMessageHandler(delegate: self)
        scriptMessageHandler = handler
        configuration.userContentController.add(handler, name: "CMSScriptMessageChannel")
    }
    
    
    public func clearCache() {
        let dateFrom: NSDate = NSDate.init(timeIntervalSince1970: 0)
        let websiteDataTypes: NSSet = WKWebsiteDataStore.allWebsiteDataTypes() as NSSet
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set, modifiedSince: dateFrom as Date) {
            STProjectHelper.Log("清空缓存完成")
        }
    }
    
    
    @objc public func cleanup() {
        if hasCleanedUp {
            return
        }
        hasCleanedUp = true
        
        stopLoading()
        
        
        configuration.userContentController.removeScriptMessageHandler(forName: "CMSScriptMessageChannel")
        scriptMessageHandler = nil
        
        
        uiDelegate = nil
        navigationDelegate = nil
        
        
        configuration.userContentController.removeAllUserScripts()
        
        
        hideLoadingIndicator()
        
        
        subviews.forEach { $0.removeFromSuperview() }
    }

    deinit {
        cleanup()
        STProjectHelper.Log("webview释放")
    }
    
}

/// A weak forwarding handler prevents WKUserContentController from retaining
/// STMiniWebView through its JavaScript bridge registration.
private final class STWeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}


extension STMiniWebView: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        
        if message.name == "CMSScriptMessageChannel" {
            
            STWebApiManager.dealWithApiMessage(message.body, webView: self)
        }
    }
    
}


extension STMiniWebView: WKUIDelegate {
    
    
    
    
    
    
    
    
    
}


extension STMiniWebView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        STProjectHelper.Log("加载周期：\(String(describing: navigationAction.request.url?.absoluteString))")
        
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        decisionHandler(.allow)
    }
    
    
    
    
    
    
    public func webView(_ webView: WKWebView,
                        didStartProvisionalNavigation navigation: WKNavigation!) {
        STProjectHelper.Log("加载周期：开始加载")

        showLoadingIndicator()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        STProjectHelper.Log("加载周期：加载完成")
        
        hideLoadingIndicator()
        (webView as! STMiniWebView).bindCrl?.webviewDidFinish()
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        STProjectHelper.Log("加载周期：渲染完成")
        
        hideLoadingIndicator()
        webView.evaluateJavaScript("document.title") { (result, error) -> Void in if error == nil {
            guard let title = result as? String else {
                return
            }
            STProjectHelper.Log("加载周期：网页标题：\(title)")
            (webView as! STMiniWebView).bindCrl?.title = title
        }}
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        STProjectHelper.Log("加载周期：加载失败 - didFail domain=\(nsError.domain) code=\(nsError.code)")
        
        hideLoadingIndicator()
        (webView as? STMiniWebView)?.bindCrl?.webviewDidFail?(nsError)
    }
    
    public func webView(_ webView: WKWebView,
                        didFailProvisionalNavigation navigation: WKNavigation!,
                        withError error: Error) {
        let nsError = error as NSError
        STProjectHelper.Log("加载周期：加载失败 - didFailProvisionalNavigation domain=\(nsError.domain) code=\(nsError.code)")
        
        hideLoadingIndicator()
        (webView as? STMiniWebView)?.bindCrl?.webviewDidFail?(nsError)
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        STProjectHelper.Log("加载周期：页面发生错误")
        // The callback is delivered for the WebView whose content process
        // died.  Do not hard-code the Mini root here: Mini-owned `/web` pages
        // are STWebH5Crl instances and must recover their own document too.
        (webView as? STMiniWebView)?.bindCrl?.webviewContentProcessDidTerminate()
        hideLoadingIndicator()
    }
    
}
