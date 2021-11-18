//
//  Debouncer.swift
//  inputTest2
//
//  Created by howard on 2021/10/27.
//

import Foundation

public class Debouncer {
    
    // MARK: - Properties
    private let queue: DispatchQueue
    private var workItem = DispatchWorkItem(block: {})
    private var minimumDelay: TimeInterval
    
    // MARK: - Initializer
    public init(minimumDelay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }
    
    // MARK: - Debouncing function
    public func debounce(action: @escaping (() -> Void)) {
        workItem.cancel()
        workItem = DispatchWorkItem(block: { action() })
        queue.asyncAfter(deadline: .now() + minimumDelay, execute: workItem)
    }
}

