# SwiftUIBase

Reusable SwiftUI base components for iOS and macOS.

## Requirements

- Swift 6.0+
- iOS 15+ / macOS 12+

## Installation (Swift Package Manager)

In Xcode, add this package via **File > Add Package Dependencies...** and select your repository URL.

Or add it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hoangnam714/SwiftUIBase.git", from: "1.0.0")
]
```

Then import in your file:

```swift
import SwiftUIBase
```

## Build as Framework (XCFramework)

If you want to distribute this library as a framework instead of integrating via SPM:

1. Build XCFramework:

```bash
./scripts/build_xcframework.sh
```

2. Output artifact:

```bash
build/SwiftUIBase.xcframework
```

Optional (for module-stable distribution):

```bash
BUILD_FOR_DISTRIBUTION=YES ./scripts/build_xcframework.sh
```

3. Integrate into your app:
- Drag `SwiftUIBase.xcframework` into your Xcode project
- Ensure **Embed & Sign** is set for app targets that use it

## Documentation

| Module | Description |
|--------|-------------|
| [UI Components](docs/UI.md) | Navigation bar, tags, WebView, utilities |
| [In-App Purchase](docs/InApp.md) | `InappHelper` — setup, purchase, restore |

## Versioning

This package follows SemVer via git tags.  
Current first release tag: `1.0.0`.
