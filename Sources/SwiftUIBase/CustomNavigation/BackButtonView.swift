//
//  BackButtonView.swift
//  SwiftUIBase
//
//  Created by Aland on 12/5/26.
//


import SwiftUI

/// A reusable back button view with configurable icon source and styling.
public struct BackButtonView: View {
    public let icon: IconSource
    public var buttonSize: CGFloat = 36
    public var iconSize: CGFloat = 18
    public var iconTint: Color = .primary
    public let onTap: () -> Void

    /// Creates a back button using an SF Symbol icon name.
    ///
    /// - Parameters:
    ///   - systemName: SF Symbol name for the back icon.
    ///   - buttonSize: Tappable button frame size.
    ///   - iconSize: Icon font size.
    ///   - iconTint: Icon tint color.
    ///   - onTap: Action called when button is tapped.
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

    /// Creates a back button using a custom `IconSource`.
    ///
    /// - Parameters:
    ///   - icon: Icon source (system or asset).
    ///   - buttonSize: Tappable button frame size.
    ///   - iconSize: Icon font size.
    ///   - iconTint: Icon tint color.
    ///   - onTap: Action called when button is tapped.
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

