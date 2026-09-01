






import Foundation
import CoreVideo


protocol STWebApiHandler {
    
    
    
    
    
    
    static func callBack<T>(_ info: [String: Any], model: T) where T: STWebApiForm
    
}


protocol STWebApiForm {
    
    
    var webview: STMiniWebView? { get }
    
    var method: String { get }

    /// A request can be concurrent with other Bridge calls.  The native
    /// callback must preserve this identifier so the H5 Promise resolves the
    /// response that belongs to it.
    var methodId: String { get }
    
    var params: [String: Any] { get }
    
    associatedtype Handler: STWebApiHandler
    
}






