//
//  Throttler.swift
//  SwiftSample
//
//  Created by wjw on 2025/12/4.
//

import Foundation
import UIKit


// MARK: - Throttler
class Throttler {
    private var workItem: DispatchWorkItem?
    private var lastRunTime: Date?
    private let interval: TimeInterval
    private let queue: DispatchQueue
    private let mode: ThrottleMode
    
    enum ThrottleMode {
        case leading    //立即执行第一次
        case trailing   //立即执行最后一次
    }
    
    init(interval: TimeInterval, queue: DispatchQueue = .main, mode: ThrottleMode = .trailing) {
        self.interval = interval
        self.queue = queue
        self.mode = mode
    }
    
    func throttle(action: @escaping () -> Void) {
        switch mode {
        case .leading:
            throttleLeading(action: action)
        case .trailing:
            throttleTrailing(action: action)
        }
    }
    
    private func throttleLeading(action: @escaping () -> Void) {
        let now = Date()
        if let lastRun = lastRunTime {
            let timeSinceLastRun = now.timeIntervalSince(lastRun)
            if timeSinceLastRun < interval {
                return
            }
        }
        action()
        lastRunTime = now
    }
    
    private func throttleTrailing(action: @escaping () -> Void) {
        //取消之前的任务
        workItem?.cancel()
        
        //创建新的任务
        let newWorkItem = DispatchWorkItem {[weak self] in
            action()
            self?.lastRunTime = Date()
            self?.workItem = nil
        }
        workItem = newWorkItem
        
        //延迟执行
        queue.asyncAfter(deadline: .now() + interval, execute: newWorkItem)
        func cancel() {
            workItem?.cancel()
            workItem = nil
        }
    }
}

// MARK: - UIControl 节流扩展
extension UIControl {
    func addThrottle(event: UIControl.Event, interval: TimeInterval, action: @escaping() -> Void) {
        let throttler = Throttler(interval: interval)
        objc_setAssociatedObject(self, "throttle", throttler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, "throttleAction", action as Any, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        self.addTarget(self, action: #selector(handleThrottledEvent), for: event)
    }
    
    @objc private func handleThrottledEvent() {
        guard let throttler = objc_getAssociatedObject(self, "throttler") as? Throttler,
              let action = objc_getAssociatedObject(self, "throttlerAction") as? () -> Void else {return}
        
        throttler.throttle (action: action)
    }
}

/**
 
 // MARK: - 使用示例
 class ThrottleViewController: UIViewController {
     @IBOutlet weak var scrollView: UIScrollView!
     @IBOutlet weak var sendButton: UIButton!
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // 节流示例：滚动事件
         scrollView.delegate = self
         
         // 节流示例：按钮连续点击
         sendButton.addThrottle(event: .touchUpInside, interval: 1.0) {
             self.sendMessage()
         }
     }
     
     func sendMessage() {
         print("发送消息 - \(Date())")
     }
 }
 */

extension UIViewController : UIScrollViewDelegate {
    func scrollViewDisScroll(_ scrollView: UIScrollView) {
        //使用节流处理滚动事件
        ThrottlerManager.shared.scrollThrottler.throttle{
            self.handleScroll()
        }
    }
    
    func handleScroll() {
        print("⬆️处理滚动事件⬇️ - \(Date())")
    }
}

// MARK: - 单例管理器
class ThrottlerManager {
    static let shared = ThrottlerManager()
    let scrollThrottler: Throttler
    let networkThrottler: Throttler
    
    private init() {
        scrollThrottler = Throttler(interval: 0.3)
        networkThrottler = Throttler(interval: 2.0)
    }
}
