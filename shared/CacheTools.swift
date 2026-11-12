import Foundation
import Nuke

/// 清空「可再生」的缓存：浏览过的图片（内存 + 磁盘）、接口结果缓存、系统 URL 缓存。
/// 不碰收藏数据，也不碰 iOS 小组件专用缩略图（那是独立保存的副本）。
enum CacheTools {
    private static var dataCache: DataCache? { ImagePipeline.shared.configuration.dataCache as? DataCache }

    static func clearAll() {
        ImagePipeline.shared.cache.removeAll()
        dataCache?.removeAll()
        URLCache.shared.removeAllCachedResponses()
        PageCache.clear()
    }

    /// 图片磁盘缓存占用，字节。
    static func imageCacheSize() -> Int {
        dataCache?.flush()
        return dataCache?.totalSize ?? 0
    }

    static func format(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
