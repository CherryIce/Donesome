






import Foundation
import UIKit


@objc public enum STWebMode: Int {
    case h5
    case online
    case local
}


@objc public enum STWebOpenSource: Int {
    case h5
    case mini
}


@objc public class STWebConfig: NSObject {
    @objc public var webMode: STWebMode = .online
    public var path: String?          
    @objc public var params: [String: String]?  
    /// The original mini:// URL. It is native-only metadata used to remember
    /// a successfully installed online package's update source; it is never
    /// exposed to the mini program JavaScript runtime.
    public var sourceLink: String?
    public var openSource: STWebOpenSource = .h5 
    
    public override init() {
        super.init()
    }
    
    public init(webMode: STWebMode) {
        self.webMode = webMode
        super.init()
    }
    
    public init(webMode: STWebMode, path: String? = nil, params: [String: String]? = nil) {
        self.webMode = webMode
        self.path = path
        self.params = params
        super.init()
    }
}

@objc public enum STWebEnv: Int {
    case normal
    case card
    case pop
}
