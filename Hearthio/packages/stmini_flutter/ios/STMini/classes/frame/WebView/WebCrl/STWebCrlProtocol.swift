






import Foundation
import UIKit


@objc public protocol STWebCrlProtocol: NSObjectProtocol {
    
    
    var config: STWebConfig! { get set }
    var webView: STMiniWebView! { get set }
    
    
    func webviewDidFinish()

    /// Main-document navigation failures are optional because Mini roots own
    /// their package-loading error flow, while ordinary H5 pages need a
    /// visible retry state instead of an empty WebView.
    @objc optional func webviewDidFail(_ error: NSError)

    /// WKWebView owns a separate Web Content process.  The callback belongs to
    /// the concrete controller that owns the affected WebView, which can be a
    /// Mini root or a Mini-owned H5 child page.
    func webviewContentProcessDidTerminate()
    
    func close()
    
}
