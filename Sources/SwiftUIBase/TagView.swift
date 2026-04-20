import SwiftUI

// MARK: - Generic TagView that accepts any Item type
public struct TagView<Item, Content: View>: View {
    public var hSpacing: CGFloat
    public var vSpacing: CGFloat
    public var lineLimit: Int?

    public var items: [Item]
    public let contentBuilder: (Item) -> Content

    @State private var measuredSizes: [Int: CGSize] = [:]
    @State private var frames: [Int: CGRect] = [:]
    @State private var totalHeight: CGFloat = .zero

    public init(
        items: [Item],
        hSpacing: CGFloat = 8,
        vSpacing: CGFloat = 8,
        lineLimit: Int? = nil,
        @ViewBuilder contentBuilder: @escaping (Item) -> Content
    ) {
        self.items = items
        self.hSpacing = hSpacing
        self.vSpacing = vSpacing
        self.lineLimit = lineLimit
        self.contentBuilder = contentBuilder
    }

    private var validFrameIndices: [Int] {
        frames.keys
            .filter { $0 >= 0 && $0 < items.count }
            .sorted()
    }

    public var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                ForEach(validFrameIndices, id: \.self) { i in
                    if let f = frames[i] {
                        contentBuilder(items[i])
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: f.width, height: f.height, alignment: .leading)
                            .offset(x: f.origin.x, y: f.origin.y)
                    }
                }

                ForEach(items.indices, id: \.self) { i in
                    contentBuilder(items[i])
                        .fixedSize()
                        .background(
                            GeometryReader { cellGeo in
                                Color.clear.preference(
                                    key: TagSizePreferenceKey.self,
                                    value: [i: cellGeo.size]
                                )
                            }
                        )
                        .hidden()
                }
            }
            .onPreferenceChange(TagSizePreferenceKey.self) { sizes in
                measuredSizes = sizes
                recomputeFrames(containerWidth: g.size.width)
            }
            .onChange(of: g.size.width) { _ in
                recomputeFrames(containerWidth: g.size.width)
            }
            .onChange(of: items.count) { _ in
                measuredSizes = measuredSizes.filter { $0.key >= 0 && $0.key < items.count }
                frames = frames.filter { $0.key >= 0 && $0.key < items.count }
                totalHeight = frames.values.map { $0.maxY }.max() ?? 0
            }
        }
        .frame(height: totalHeight)
    }

    private func recomputeFrames(containerWidth: CGFloat) {
        guard !measuredSizes.isEmpty, containerWidth > 0 else { return }

        var newFrames: [Int: CGRect] = [:]
        var x: CGFloat = 0
        var y: CGFloat = 0
        var currentLine = 1
        var lineHeight: CGFloat = 0
        let maxWidth = containerWidth

        for i in items.indices {
            guard let measured = measuredSizes[i] else { continue }

            let itemWidth = min(measured.width, maxWidth)
            let itemHeight = measured.height

            if x > 0, x + itemWidth > maxWidth {
                x = 0
                y += lineHeight + vSpacing
                currentLine += 1
                lineHeight = 0
            }

            if let limit = lineLimit, currentLine > limit {
                break
            }

            newFrames[i] = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)

            x += itemWidth + hSpacing
            lineHeight = max(lineHeight, itemHeight)
        }

        let newHeight = max(newFrames.values.map { $0.maxY }.max() ?? 0, 0)
        frames = newFrames
        totalHeight = newHeight
    }
}

private struct TagSizePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGSize] { [:] }
    static func reduce(value: inout [Int: CGSize], nextValue: () -> [Int: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

