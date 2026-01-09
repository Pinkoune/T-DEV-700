import Foundation

struct Config {
    static let baseURL: String = {
        #if DEBUG
        return "http://10.15.193.166"
        #else
        return "https://pourLaProduction.com"
        #endif
    }()
}
