import SwiftUI

/// 瀑布流：每列等宽，每张图高度按原图比例；新图放进当前最矮的一列。
/// 每列是 LazyVStack，只渲染可见区域附近的图。
struct MasonryGrid<Content: View>: View {
    let photos: [Photo]
    var minColumnWidth: CGFloat = 220
    var maxColumns = 6
    /// 折叠屏建议使用偶数列，合页处能对半分。
    var preferEvenColumns = false
    var spacing: CGFloat = 12
    var padding: CGFloat = 16
    var footer: AnyView? = nil
    @ViewBuilder let content: (Photo, CGSize) -> Content

    var body: some View {
        GeometryReader { geo in
            let inner = max(geo.size.width - padding * 2, minColumnWidth)
            let raw = min(maxColumns, max(1, Int((inner + spacing) / (minColumnWidth + spacing))))
            let count = (preferEvenColumns && raw > 2 && raw % 2 == 1) ? raw - 1 : raw
            let colWidth = (inner - spacing * CGFloat(count - 1)) / CGFloat(count)
            let columns = Self.distribute(photos, count: count, width: colWidth, spacing: spacing)

            ScrollView {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(0..<count, id: \.self) { index in
                        LazyVStack(spacing: spacing) {
                            ForEach(columns[index]) { photo in
                                let size = CGSize(width: colWidth, height: colWidth * CGFloat(photo.height) / CGFloat(photo.width))
                                content(photo, size)
                                    .frame(width: size.width, height: size.height)
                            }
                        }
                        .frame(width: colWidth)
                    }
                }
                .padding(padding)
                if let footer { footer.padding(.bottom, padding) }
            }
        }
    }

    private static func distribute(_ photos: [Photo], count: Int, width: CGFloat, spacing: CGFloat) -> [[Photo]] {
        var heights = [CGFloat](repeating: 0, count: count)
        var columns = [[Photo]](repeating: [], count: count)
        for photo in photos {
            let target = heights.indices.min { heights[$0] < heights[$1] } ?? 0
            columns[target].append(photo)
            heights[target] += width * CGFloat(photo.height) / CGFloat(photo.width) + spacing
        }
        return columns
    }
}
