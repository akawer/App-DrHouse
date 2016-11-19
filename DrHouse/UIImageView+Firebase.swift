//
//  UIImageView+Firebase.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/18/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit
import Firebase

extension UIImageView {
    
    func setImage(post: Post) {
        setImage(firebaseURL: post.imageUrl)
    }
    
    
    func setImage(firebaseURL: String) {
    
        
        if let img = FeedVC.imageCache.object(forKey: firebaseURL as NSString) {
            image = img
            return
        }
        
        if firebaseURL.characters.count > 0 {
                
            let ref = FIRStorage.storage().reference(forURL: firebaseURL)
            ref.data(withMaxSize: 2 * 5000 * 5000, completion: { (data, error) in
                if error != nil {
                    print("NEGROKO: Unable to download image from Firebase storage")
                } else {
                    print("NEGROKO: Image downloaded from Firebase storage")
                    if let imgData = data {
                        if let img = UIImage(data: imgData) {
                            self.image = img
                            FeedVC.imageCache.setObject(img, forKey: firebaseURL as NSString)
                        }
                    }
                }
            })
                
        }
        
    }
}
