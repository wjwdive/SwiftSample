//
//  Debounce.swift
//  SwiftSample
//
//  Created by wjw on 2025/12/4.
//

import Foundation
import UIKit

// MARK: - Debouncer
class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    private let queue: DispatchQueue
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(action: @escaping ()-> Void) {
        //取消之前的任务
        workItem?.cancel()
        
        //创建新的任务
        let newWorkItem = DispatchWorkItem { action() }
        workItem = newWorkItem
        
        // 延迟执行
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

//MARK: - UIView 扩展
extension UIView {
    private struct AssociatedKeys {
        static var debouncer = "debouncer"
    }
    
    var debouncer: Debouncer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.debouncer) as? Debouncer
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.debouncer, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    
    func addDebounceTapGesture(delay: TimeInterval = 0.5, action :@escaping () -> Void) {
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDebouncedTap(_:)))
        addGestureRecognizer(tapGesture)
        debouncer = Debouncer(delay: delay)
        
        objc_setAssociatedObject(self, "debounceAction", action as Any, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc private func handleDebouncedTap(_ sender: UITapGestureRecognizer) {
        guard let action = objc_getAssociatedObject(self, "debounceAction") as? () -> Void else {return}
        debouncer?.debounce(action: action)
    }
    
}




