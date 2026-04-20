import SwiftUI

public enum IconSource: Equatable {
    case system(String)
    case asset(String, bundle: Bundle? = nil)
}

extension IconSource {
    var image: Image {
        switch self {
        case .system(let name):
            return Image(systemName: name)
        case .asset(let name, let bundle):
            return Image(name, bundle: bundle)
        }
    }
}

