//
//  FeedVC.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/3/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircularView!
    @IBOutlet weak var captionField: UpgradedField!
    
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    var imageSelected = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 340.0
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        
        if let ref = DataService.ds.REF_MY_POSTS {
            
            // Observe new data
            ref.observe(.childAdded, with: { (snapshot) in
                
                DispatchQueue.main.async {
                    if snapshot.exists() {
                        
                            
                        if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                            let key = snapshot.key
                            let post = Post(postKey: key, postData: postDict)
                            post.postRef = snapshot.ref
                            self.posts.insert(post, at: 0)
                        }
                        
                    }
                    self.tableView.reloadData()
                }
            })
            
            // Observe changes
            ref.observe(.childChanged, with: { (snapshot: FIRDataSnapshot) in
                if snapshot.exists() {
                    
                    DispatchQueue.main.async {
                        if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                            let key = snapshot.key
                            
                            // Replace the old post with a new one
                            var index = 0
                            for post in self.posts {
                                if key == post.postKey {
                                    break
                                }
                                index += 1
                            }
                            self.posts.remove(at: index)
                            
                            let post = Post(postKey: key, postData: postDict)
                            post.postRef = snapshot.ref
                            self.posts.insert(post, at: index)
                        }
                        self.tableView.reloadData()
                    }
                }
            })
        }
        
        
    }
    
    // -------------------------
    // MARK - Table View
    // -------------------------
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img)
                return cell
            } else {
                cell.configureCell(post: post)
                return cell
            }
        } else {
            return PostCell()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let post = posts[indexPath.row]
            // Remove from Firebase
            post.postRef.removeValue()
            // Delete the image
            if post.imageUrl.characters.count > 0 { // if it has a URL
                FIRStorage.storage().reference(forURL: post.imageUrl).delete(completion: { (error: Error?) in
                    
                })
            }
            // Remove from the local array
            posts.remove(at: indexPath.row)
            // Reload the UI
            tableView.reloadData()
        default:
            break
        }
    }
    
    
    // -------------------------
    // MARK - Image Picking
    // -------------------------
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
        } else {
            print("NEGROKO: A valid image wasn't selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func addImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func postBtnTapped(_ sender: Any) {
        guard let caption = captionField.text, caption != "" else {
            print("NEGROKO: Caption must be entered")
            return
        }
        
        guard let img = imageAdd.image, imageSelected == true else {
            print("NEGROKO: An image must be selected")
            self.postToFirebase(imgUrl: "")  // Post without an image 
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("NEGROKO: Unable to upload image to Firebasee torage")
                } else {
                    print("NEGROKO: Successfully uploaded image to Firebase storage")
                    //_ = metadata?.downloadURL()?.absoluteString
                    
                    // erase this and use line above only
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        self.postToFirebase(imgUrl: url)
                    }
                }
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        
        // Make sure the user is logged in
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let post : [String : Any] = [
            "caption": captionField.text!,
            "imageUrl": imgUrl,
            "likes": 0,
            "userId" : uid,
            "inverseTimestamp" : Date().timeIntervalSince1970 * -1.0
        ]
        
        if let firebasePost = DataService.ds.REF_MY_POSTS?.childByAutoId() {
            firebasePost.setValue(post)
        }
        
        captionField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
        
        tableView.reloadData()
    }
    
    
    @IBAction func signOutTapped(_ sender: Any) {
        let keyChainResult = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("NEGROKO: ID removed from Keychain \(keyChainResult)")
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    // as AnyObject
}
