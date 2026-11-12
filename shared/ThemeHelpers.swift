import SwiftUI

extension View {
    /// 页面级背景：用主题的 Background 铺满，滚动容器（List / Form）里隐藏系统背景。
    func appPage() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }

    /// 列表 / 表单分组里的行背景用主题的 Surface。
    func appRows() -> some View {
        listRowBackground(Color.appSurface)
    }
}
