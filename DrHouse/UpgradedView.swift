//
//  UpgradedView.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/3/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit

class UpgradedView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.shadowColor = UIColor(red: SHADOW_GRAY, green: SHADOW_GRAY, blue: SHADOW_GRAY, alpha: 0.6).cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        
    }

}
