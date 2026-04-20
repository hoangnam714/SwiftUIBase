import SwiftUI

public struct BackButtonView: View {
    public let icon: IconSource
    public var buttonSize: CGFloat = 36
    public var iconSize: CGFloat = 18
    public var iconTint: Color = .primary
    public let onTap: () -> Void

    public init(
        systemName: String = "chevron.left",
        buttonSize: CGFloat = 36,
        iconSize: CGFloat = 18,
        iconTint: Color = .primary,
        onTap: @escaping () -> Void = {}
    ) {
        self.icon = .system(systemName)
        self.buttonSize = buttonSize
        self.iconSize = iconSize
        self.iconTint = iconTint
        self.onTap = onTap
    }

    public init(
        icon: IconSource,
        buttonSize: CGFloat = 36,
        iconSize: CGFloat = 18,
        iconTint: Color = .primary,
        onTap: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.buttonSize = buttonSize
        self.iconSize = iconSize
        self.iconTint = iconTint
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            icon.image
                .renderingMode(.template)
                .foregroundStyle(iconTint)
                .font(.system(size: iconSize, weight: .semibold))
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

