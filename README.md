# SwiftUIBase

Reusable SwiftUI base components for iOS and macOS.

## Requirements

- Swift 6
- iOS 15+ / macOS 12+

## Installation (Swift Package Manager)

In Xcode, add this package via **File > Add Package Dependencies...** and select your repository URL.

Or add it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftUIBase.git", from: "1.0.0")
]
```

Then import in your file:

```swift
import SwiftUIBase
```

## Components

### `BackButtonView`

A customizable back button with system icon or asset icon.

```swift
BackButtonView(systemName: "chevron.left") {
    dismiss()
}
```

Use custom icon source:

```swift
BackButtonView(
    icon: .asset("ic_back_custom", bundle: .main),
    buttonSize: 40,
    iconSize: 18
) {
    dismiss()
}
```

### `CustomNavigationBar`

A simple custom navigation bar with `leading`, `center`, and `trailing` slots.

```swift
CustomNavigationBar {
    CustomNavigationButtonView(style: .leading) {
        BackButtonView(systemName: "chevron.left") { dismiss() }
    }

    CustomNavigationButtonView(style: .center) {
        Text("Detail")
            .font(.headline)
    }

    CustomNavigationButtonView(style: .trailing) {
        Image(systemName: "ellipsis")
    }
}
```

### `TagView`

Flow layout for tags/chips with configurable spacing and optional line limit.

```swift
let tags = ["SwiftUI", "SPM", "Reusable", "Base"]

TagView(items: tags, hSpacing: 8, vSpacing: 8, lineLimit: 2) { tag in
    Text(tag)
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule())
}
```

### `WebView`

A native `WKWebView` wrapper for SwiftUI with loading state and progress binding.

```swift
@State private var isLoading = true
@State private var progress = 0.0

var body: some View {
    WebView(
        url: URL(string: "https://developer.apple.com")!,
        isLoading: $isLoading,
        progress: $progress
    )
}
```

### `WebContentView`

Ready-to-use screen for web content:
- custom title
- back action
- loading progress bar
- embedded `WebView`

```swift
WebContentView(
    title: "Terms & Conditions",
    urlString: "https://example.com/terms"
)
```

### `hideNavigationBar()`

Utility extension to hide native navigation bar safely for iOS versions.

```swift
var body: some View {
    content
        .hideNavigationBar()
}
```

## Versioning

This package follows SemVer via git tags.  
Current first release tag: `1.0.0`.
