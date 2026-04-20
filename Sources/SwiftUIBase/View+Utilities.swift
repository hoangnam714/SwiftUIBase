import SwiftUI

extension View {
    func hideNavigationBar() -> some View {
        #if os(iOS)
        return self.navigationBarBackButtonHidden(true).modifier(HideNavigationBarModifier())
        #else
        return self
        #endif
    }
}

private struct HideNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            content.toolbar(.hidden, for: .navigationBar)
        } else {
            content.navigationBarHidden(true)
        }
        #else
        content
        #endif
    }
}

