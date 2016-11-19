//
//  Post.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/8/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import Foundation
import Firebase

class Post {
    public private(set) var caption: String!
    public private(set) var imageUrl: String!
    private var _likes: Int!
    private var _postKey: String!
    var postRef: FIRDatabaseReference!
    var userId : String?
    var timestamp : Date?
    
//    var imageUrl: String {
//        return _imageUrl
//    }
    
    var likes: Int {
        return _likes
    }
    
    var postKey: String {
        return _postKey
    }
    
    init(caption: String, imageUrl: String, likes: Int) {
        self.caption = caption
        self.imageUrl = imageUrl
        self._likes = likes
    }
    
    init(postKey: String, postData: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let caption = postData["caption"] as? String {
            self.caption = caption
        }
        
        if let imageUrl = postData["imageUrl"] as? String {
            self.imageUrl = imageUrl
        }
        
        if let likes = postData["likes"] as? Int{
            self._likes = likes
        }
        
        userId = postData["userId"] as? String
        if let inverseTimestamp = postData["inverseTimestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: inverseTimestamp * -1.0)
        }
        
        postRef = DataService.ds.REF_POSTS.child(_postKey)
    }
    
    func adjustLikes(addLike: Bool) {
        if addLike {
            _likes = _likes + 1
        } else {
            _likes = likes - 1
        }
        postRef.child("likes").setValue(_likes)
        
    }
    
}
