






import Foundation


struct STWebApiModel: STWebApiForm {
    
    
    weak var webview: STMiniWebView?
    
    var method: String = ""
    
    var methodId: String = ""
    
    var params: [String: Any] = [:]
    
    typealias Handler = STWebApiManager
    
    
    init(dict: [String: Any]) {
        method = (dict["method"] != nil) ? dict["method"] as! String : ""
        params = (dict["params"] != nil) ? dict["params"] as! [String: Any] : [:]
        methodId = (params["methodId"] != nil) ? params["methodId"] as! String : ""
    }
    
}
