import UIKit
import Foundation

/// 热点列表项数据模型
struct HotListItem: Identifiable {
    /// 标题
    let title: String
    
    /// 副标题
    let subtitle: String
    
    /// 图标URL
    let iconURL: URL?
    
    /// 唯一标识符
    let id: UUID
    
    //图片URL
    let imageUrl: String?
    
    /// 定时器开始时间（时间戳，秒）
    var startTime: TimeInterval?
    
    /// 倒计时总时间（秒）
    let totalTime: TimeInterval = 3600 // 1小时（01:00:00）
    
    /// 已流逝时间（秒）
    var elapsedSeconds: TimeInterval = 0
    
    /// 定时器是否运行
    var isTimerRunning: Bool = false
    
    /// 初始化方法
    /// - Parameters:
    ///   - title: 标题
    ///   - subtitle: 副标题
    ///   - imageUrl: 图标URL字符串
    ///   - id: 唯一标识符，默认使用UUID生成
    init(title: String, subtitle: String, imageUrl: String? = nil, id: UUID = UUID()) {
        self.title = title
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.iconURL = imageUrl.flatMap { URL(string: $0) }
        self.id = id
    }
    
    /// 获取当前剩余时间（秒）
    /// - Returns: 当前剩余时间
    func getCurrentTime() -> TimeInterval {
        var totalElapsed = elapsedSeconds
        
        if isTimerRunning, let startTime = startTime {
            // 定时器运行中，计算从startTime到当前的时间差
            let currentTime = Date().timeIntervalSince1970
            let elapsed = currentTime - startTime
            totalElapsed += elapsed
        }
        
        // 计算剩余时间，确保不小于0
        let remainingTime = max(0, totalTime - totalElapsed)
        return remainingTime
    }
    
    mutating func startTimer() {
        // 只有当定时器未运行时才启动
        guard !isTimerRunning else { return }
        
        // 设置启动时间为当前时间戳
        startTime = Date().timeIntervalSince1970
        isTimerRunning = true
    }
    
    mutating func pauseTimer() {
        // 只有当定时器正在运行且startTime存在时才暂停
        guard isTimerRunning, let startTime = startTime else { return }
        
        // 计算从启动到现在的时间并累加到总时间
        let currentTime = Date().timeIntervalSince1970
        let elapsed = currentTime - startTime
        elapsedSeconds += elapsed
        
        // 重置启动时间并标记为暂停
        self.startTime = nil
        isTimerRunning = false
    }
}
