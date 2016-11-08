//
//  PostCell.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/7/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell {

    @IBOutlet weak var profileImg : UIImageView!
    @IBOutlet weak var usernameLbl : UILabel!
    @IBOutlet weak var postImg : UIImageView!
    @IBOutlet weak var caption : UITextView!
    @IBOutlet weak var likesLbl : UILabel!
    
    var post: Post!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(post: Post) { //, img: UIImage? = nil) {
        self.post = post
        self.caption.text = post.caption
        self.likesLbl.text = "\(post.likes)"
    }
    
    
    

}
