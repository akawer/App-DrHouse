//
//  TimestampLabel.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/18/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import Foundation
import UIKit
import SwiftyTimer
import NSDate_TimeAgo

/**
 Label that automatically updates it's text according to the specified timestamp's time ago
 */
class TimestampLabel: UILabel {
    
    
    // -------------------------------------------------------------------------------
    // MARK: - Properties
    // -------------------------------------------------------------------------------
    
    fileprivate var timeUpdateTimer : Timer?
    
    var timestamp : Date?
    
    
    
    // -------------------------------------------------------------------------------
    // MARK: - Configuration
    // -------------------------------------------------------------------------------
    
    func configure(_ timestamp: Date) {
        self.timestamp = timestamp
        text = (timestamp as NSDate).timeAgoSimple()
        timeUpdateTimer?.invalidate()
        
        let timeInterval = max(10, Date().timeIntervalSince(timestamp))
        
        timeUpdateTimer = Timer.every(timeInterval) {[weak self] in
            self?.text = (timestamp as NSDate).timeAgoSimple()
        }
    }
    
    func clear() {
        text = nil
        timeUpdateTimer?.invalidate()
    }
    
}
