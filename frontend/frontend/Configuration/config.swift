import Foundation

struct Config {
    static let baseURL: String = {
        #if DEBUG
        return "http://localhost"
        #else
        return "https://pourLaProduction.com"
        #endif
    }()
}