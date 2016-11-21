//
//  PostCell.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/7/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit
import Firebase

class PostCell: UITableViewCell {

    @IBOutlet weak var profileImg : UIImageView!
    @IBOutlet weak var usernameLbl : UILabel!
    @IBOutlet weak var postImg : UIImageView!
    @IBOutlet weak var caption : UITextView!
    @IBOutlet weak var likesLbl : UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var timestampLabel: TimestampLabel!
    
    var userReference: FIRDatabaseReference?
    var userHandle: FIRDatabaseHandle?
    
    var post: Post!
    var likesRef: FIRDatabaseReference!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        tap.numberOfTapsRequired = 1
        likeImg.addGestureRecognizer(tap)
        likeImg.isUserInteractionEnabled = true
    }
    
    func configureCell(post: Post, img: UIImage? = nil) {
        self.post = post
        likesRef = DataService.ds.REF_USER_CURRENT.child("likes").child(post.postKey)
        self.caption.text = post.caption
        self.likesLbl.text = "\(post.likes)"
        self.postImg.image = nil
        self.usernameLbl.text = nil
        self.profileImg.image = nil
        
        // Set the post image
        if img != nil {
            self.postImg.image = img
            imageHeightConstraint.constant = 150.0
        } else {
            if post.imageUrl.characters.count > 0 {
                imageHeightConstraint.constant = 150.0
            
                postImg.setImage(post: post)
            } else {
                imageHeightConstraint.constant = 0.0
            }
        }
        layoutIfNeeded()
        
        // Set the like status
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likeImg.image = UIImage(named: "empty-star")
            } else {
                self.likeImg.image = UIImage(named: "filled-star")
            }
        })
        
        // Clean the user's observing
        if let handle = userHandle, let ref = userReference {
            ref.removeObserver(withHandle: handle)
        }
        
        // If the post has a userId
        if let uid = post.userId {
            // Get the user info
            userReference = DataService.ds.REF_USERS.child(uid)
            userHandle = userReference?.observe(.value, with: { (snapshot) in
                if let value = snapshot.value as? [String : Any] {
                    // Assign the username
                    self.usernameLbl.text = value["username"] as? String
                    
                    // Download the profile Image (or fetch it from the cache if available)
                    if let url = value["imageUrl"] as? String {
                        self.profileImg.setImage(firebaseURL: url)
                    }
                }
            })
        }
        
        // Set the timestamp
        if let timestamp = post.timestamp {
            timestampLabel.configure(timestamp)
        }
    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likeImg.image = UIImage(named: "filled-star")
                self.post.adjustLikes(addLike: true)
                self.likesRef.setValue(true)
            } else {
                self.likeImg.image = UIImage(named: "empty-star")
                self.post.adjustLikes(addLike: false)
                self.likesRef.removeValue()
            }
        })
    }
    
}
