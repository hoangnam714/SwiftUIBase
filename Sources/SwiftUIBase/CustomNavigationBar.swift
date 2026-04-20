import SwiftUI

public enum CustomNavStyle { case leading, center, trailing }

public struct AnyNavButton: Identifiable {
    public let id = UUID()
    public let style: CustomNavStyle
    public let action: (() -> Void)?
    public let label: AnyView

    public init(style: CustomNavStyle, action: (() -> Void)?, label: AnyView) {
        self.style = style
        self.action = action
        self.label = label
    }
}

public protocol NavButtonConvertible {
    func erase() -> AnyNavButton
}

public struct CustomNavigationButtonView<Label: View>: NavButtonConvertible {
    public let style: CustomNavStyle
    public let action: (() -> Void)?
    public let labelBuilder: () -> Label

    public init(
        style: CustomNavStyle,
        action: (() -> Void)? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.style = style
        self.action = action
        self.labelBuilder = label
    }

    public func erase() -> AnyNavButton {
        AnyNavButton(style: style, action: action, label: AnyView(labelBuilder()))
    }
}

@resultBuilder
public enum CustomNavBuilder {
    public static func buildBlock(_ components: [AnyNavButton]...) -> [AnyNavButton] { components.flatMap { $0 } }
    public static func buildExpression(_ expr: any NavButtonConvertible) -> [AnyNavButton] { [expr.erase()] }
    public static func buildExpression(_ expr: [any NavButtonConvertible]) -> [AnyNavButton] { expr.map { $0.erase() } }
    public static func buildExpression(_ expr: [AnyNavButton]) -> [AnyNavButton] { expr }
    public static func buildOptional(_ component: [AnyNavButton]?) -> [AnyNavButton] { component ?? [] }
    public static func buildEither(first component: [AnyNavButton]) -> [AnyNavButton] { component }
    public static func buildEither(second component: [AnyNavButton]) -> [AnyNavButton] { component }
    public static func buildArray(_ components: [[AnyNavButton]]) -> [AnyNavButton] { components.flatMap { $0 } }
    public static func buildFinalResult(_ component: [AnyNavButton]) -> [AnyNavButton] { component }
}

public struct CustomNavigationBar: View {
    private let buttons: [AnyNavButton]
    public var isTransparent: Bool

    public init(
        isTransparent: Bool = false,
        @CustomNavBuilder nav: () -> [AnyNavButton]
    ) {
        self.isTransparent = isTransparent
        self.buttons = nav()
    }

    private var leadingButtons: [AnyNavButton] { buttons.filter { $0.style == .leading } }
    private var centerButtons: [AnyNavButton] { buttons.filter { $0.style == .center } }
    private var trailingButtons: [AnyNavButton] { buttons.filter { $0.style == .trailing } }

    public var body: some View {
        HStack {
            if !leadingButtons.isEmpty {
                HStack(spacing: 12) {
                    ForEach(leadingButtons) { buttonView($0) }
                }
            }

            Spacer(minLength: 0)

            if !trailingButtons.isEmpty {
                HStack(spacing: 12) {
                    ForEach(trailingButtons) { buttonView($0) }
                }
            }
        }
        .frame(height: 56)
        .overlay(alignment: .center) {
            if !centerButtons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(centerButtons) { $0.label }
                }
                .padding(.horizontal, 48)
                .multilineTextAlignment(.center)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(background)
    }

    private var background: some View {
        Group {
            if isTransparent {
                Color.clear
            } else {
                ZStack(alignment: .bottom) {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(.primary.opacity(0.08))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    @ViewBuilder
    private func buttonView(_ btn: AnyNavButton) -> some View {
        let tappable = btn.label
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())

        if let action = btn.action {
            Button(action: action) { tappable }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
        } else {
            tappable
        }
    }
}

