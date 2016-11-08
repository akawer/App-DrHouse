//
//  CircularView.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/7/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit

class CircularView: UIImageView {

    override func layoutSubviews() {
        layer.cornerRadius = self.frame.width / 2
        clipsToBounds = true
    }
    
    
    
        
    

}
