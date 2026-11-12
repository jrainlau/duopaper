import SwiftUI

/// 颜色在 Colors.xcassets 里已配好 Light/Dark，系统自动切换。
extension Color {
    static let appBackground = Color("Background")
    static let appSurface = Color("Surface")
    static let appSurfaceSecondary = Color("SurfaceSecondary")
    static let appSeparator = Color("Separator")
    static let appTextPrimary = Color("TextPrimary")
    static let appTextSecondary = Color("TextSecondary")
    static let appTextTertiary = Color("TextTertiary")
    static let appPrimary = Color("Primary")
    static let appPrimaryPressed = Color("PrimaryPressed")
    static let appOnPrimary = Color("OnPrimary")
    static let appPrimarySubtle = Color("PrimarySubtle")
    static let appPrimaryText = Color("PrimaryText")
    static let appSuccess = Color("Success")
    static let appWarning = Color("Warning")
    static let appError = Color("Error")
}

extension LinearGradient {
    /// 主按钮渐变（下载等主操作）
    static let appBrand = LinearGradient(colors: [Color(red: 0.608, green: 0.365, blue: 0.898), Color(red: 0.478, green: 0.247, blue: 0.816)], startPoint: .top, endPoint: .bottom)
}
