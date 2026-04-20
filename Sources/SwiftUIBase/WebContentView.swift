import SwiftUI

public struct WebContentView: View {
    private let title: String
    private let urlString: String
    private let onBack: (() -> Void)?
    private let loadingColor: Color
    private let loadingTrackColor: Color
    private let progressHeight: CGFloat
    private let progressAnimationDuration: Double

    @State private var isLoading: Bool = true
    @State private var progress: Double = 0.0
    @Environment(\.dismiss) private var dismiss

    public init(
        title: String,
        urlString: String,
        loadingColor: Color = .accentColor,
        loadingTrackColor: Color = Color.secondary.opacity(0.15),
        progressHeight: CGFloat = 3,
        progressAnimationDuration: Double = 0.2,
        onBack: (() -> Void)? = nil
    ) {
        self.title = title
        self.urlString = urlString
        self.loadingColor = loadingColor
        self.loadingTrackColor = loadingTrackColor
        self.progressHeight = progressHeight
        self.progressAnimationDuration = progressAnimationDuration
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(isTransparent: true) {
                CustomNavigationButtonView(style: .leading) {
                    BackButtonView(icon: .system("chevron.left")) {
                        if let onBack {
                            onBack()
                        } else {
                            dismiss()
                        }
                    }
                }

                CustomNavigationButtonView(style: .center) {
                    Text(title)
                        .foregroundStyle(.primary)
                        .font(.system(size: 14, weight: .bold))
                }
            }

            if isLoading {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(loadingTrackColor)
                            .frame(height: progressHeight)

                        Rectangle()
                            .fill(loadingColor)
                            .frame(width: geometry.size.width * progress, height: progressHeight)
                            .animation(.linear(duration: progressAnimationDuration), value: progress)
                    }
                }
                .frame(height: progressHeight)
            }

            webView
        }
        .hideNavigationBar()
    }

    @ViewBuilder
    private var webView: some View {
        if let url = URL(string: urlString) {
            WebView(url: url, isLoading: $isLoading, progress: $progress)
                .ignoresSafeArea()
        } else {
            Text("Invalid URL")
                .foregroundStyle(.red)
        }
    }
}

