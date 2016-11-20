//
//  DataService.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/8/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import Foundation
import Firebase
import SwiftKeychainWrapper

let DB_BASE = FIRDatabase.database().reference()
let STORAGE_BASE = FIRStorage.storage().reference()

/*
 
 Content Filtering - tags
 1. Create index and organize content in the index so that it is easily fetchable
 2. Fetch the index
 3. Maintain the index
 
 FullText Search
 1. Index the content with key as a path and text as a value
    The content can be categorized by the letters it contains (very hardcore optimization)
 2. Download all the relevant text
 3. Perform search locally
 
 or 
 
 Implement elastic search

 
 */

class DataService {
    
    static let ds = DataService()
    
    // DB references
    private var _REF_BASE = DB_BASE
    private var _REF_POSTS = DB_BASE.child("posts")
    public private(set) var REF_POSTS_TAG_INDEX = DB_BASE.child("postTagIndex")
    private var _REF_USERS = DB_BASE.child("users")
    
    // Storage references
    private var _REF_POST_IMAGES = STORAGE_BASE.child("post-pics")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return _REF_POSTS
    }
    
    var REF_MY_POSTS_TAG_INDEX: FIRDatabaseReference? {
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            return REF_POSTS_TAG_INDEX.child(uid)
        }
        return nil
    }
    
    var REF_MY_POSTS: FIRDatabaseReference? {
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            return _REF_POSTS.child(uid)
        }
        return nil
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        //let uid = KeychainWrapper.stringForKey(KEY_UID)
        //let uid = KeychainWrapper.set(KEY_UID)
        let uid = KeychainWrapper.standard.string(forKey: KEY_UID)
        let user = REF_USERS.child(uid!)
        return user
    }
    
    var REF_POST_IMAGES: FIRStorageReference {
        return _REF_POST_IMAGES
    }
    
    func createdFireBaseDBUser(uid: String, userData: Dictionary<String, String>) {
        REF_USERS.child(uid).updateChildValues(userData)
    }
    
    
    
    

}
