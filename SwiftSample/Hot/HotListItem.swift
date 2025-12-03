import UIKit

/// 热点列表项数据模型
struct HotListItem {
    /// 标题
    let title: String
    
    /// 副标题
    let subtitle: String
    
    /// 图标URL
    let imageUrl: String?
    
    /// 唯一标识符
    let id: String
    
    /// 初始化方法
    /// - Parameters:
    ///   - title: 标题
    ///   - subtitle: 副标题
    ///   - imageUrl: 图标URL
    ///   - id: 唯一标识符，默认使用UUID生成
    init(title: String, subtitle: String, imageUrl: String? = nil, id: String = UUID().uuidString) {
        self.title = title
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.id = id
    }
}