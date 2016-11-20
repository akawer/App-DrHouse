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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FilterTableViewControllerDelegate, UITextFieldDelegate {
    
    // -------------------------
    // MARK - Properties
    // -------------------------
    
    var tag : String?
    
    var posts = [Post]()
    
    var filters : Filters?
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    var imageSelected = false
    
    // Handling the Firebase observation
    var queries = [FIRDatabaseHandle : FIRDatabaseQuery]()
    
    // -------------------------
    // MARK - Outlets
    // -------------------------
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircularView!
    @IBOutlet weak var captionField: UpgradedField!
    
    
    // -------------------------
    // MARK - Lifecycle
    // -------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        captionField.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 340.0
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        startObserving()
    }
    
    // -------------------------
    // MARK - Posts observation
    // -------------------------
    
    func stopObservingPosts() {
        // Clean the posts observing
        for (handle, query) in queries {
            query.removeObserver(withHandle: handle)
        }
    }
    
    func observePosts(ref: FIRDatabaseReference) {
        var query : FIRDatabaseQuery!
        var handle : FIRDatabaseHandle!
        if let endDate = filters?.endDate, let startDate = filters?.startDate {
            query = ref.queryOrdered(byChild: "inverseTimestamp").queryEnding(atValue: startDate.timeIntervalSince1970 * -1).queryStarting(atValue: endDate.timeIntervalSince1970 * -1)
        } else {
            query = ref.queryOrderedByKey()
        }
        
        // Observe new datastartDate
        handle = query.observe(.childAdded, with: { (snapshot) in
            
            DispatchQueue.main.async {
                if snapshot.exists() {
                    
                    
                    if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                        let key = snapshot.key
                        let post = Post(postKey: key, postData: postDict)
                        post.postRef = snapshot.ref
                        self.posts.insert(post, at: 0)
                    }
                    
                }
                self.posts.sort(by: { ($0.timestamp?.timeIntervalSince1970 ?? 0) > ($1.timestamp?.timeIntervalSince1970 ?? 0)})
                self.tableView.reloadData()
            }
        })
        queries[handle] = query
        
        // Observe changes
        handle = query.observe(.childChanged, with: { (snapshot: FIRDataSnapshot) in
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
        queries[handle] = query
    }
    
    func startObserving() {
        // Stop observing all the previous queries so we can start again
        stopObservingPosts()
        
        if let filters = filters, filters.tags.count > 0 {
            // Observe tag specific posts
            for tag in filters.tags {
                if let ref = DataService.ds.REF_MY_POSTS_TAG_INDEX?.child(tag) {
                    observePosts(ref: ref)
                }
            }
        } else {
            // Observe all posts
            if let ref = DataService.ds.REF_MY_POSTS {
                observePosts(ref: ref)
            }
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
        let actionSheet = UIAlertController(title: "Pick an image", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func postBtnTapped(_ sender: Any) {
        guard let caption = captionField.text, caption != "" else {
            print("NEGROKO: Caption must be entered")
            return
        }
        
        let tags = ["Med", "Vac", "Sym"]
        for tag in tags {
            if caption.hasPrefix(tag) {
                self.tag = tag
            }
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
        
        let inverseTimestamp = Date().timeIntervalSince1970 * -1.0
        
        let post : [String : Any] = [
            "caption": captionField.text!,
            "imageUrl": imgUrl,
            "likes": 0,
            "userId" : uid,
            "inverseTimestamp" : inverseTimestamp
        ]
        
        if let firebasePost = DataService.ds.REF_MY_POSTS?.childByAutoId() {
            firebasePost.setValue(post)
            // Add the post to the tag index of the current user
            if let tag = tag {
                DataService.ds.REF_MY_POSTS_TAG_INDEX?.child(tag).child(firebasePost.key).setValue(post)
            }
        }
        
        tag = nil
        captionField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
        tagContainerView.isHidden = false
        
        tableView.reloadData()
    }
    
    
    @IBAction func signOutTapped(_ sender: Any) {
        let keyChainResult = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("NEGROKO: ID removed from Keychain \(keyChainResult)")
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }
    
    @IBOutlet weak var tagContainerView: UIView!
    @IBAction func tagButtonTapped(_ sender: UIButton) {
        let tag = (sender.title(for: .normal)! as NSString).substring(to: 3)
        captionField.text = tag + " "
        captionField.becomeFirstResponder()
        tagContainerView.isHidden = true
    }
    
    // -------------------------
    // MARK - FilterTableViewControllerDelegate
    // -------------------------
    
    func didApply(filters: Filters) {
        self.filters = filters
        posts.removeAll()
        tableView.reloadData()
        startObserving()
    }
    
    
    // -------------------------
    // MARK - Navigation
    // -------------------------

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navc = segue.destination as? UINavigationController, let vc = navc.topViewController as? FilterTableViewController {
            vc.delegate = self
        }
    }

    // -------------------------
    // MARK - UITextFieldDelegate
    // -------------------------
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let finalText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if finalText.characters.count < 4 {
            textField.text = ""
            textField.resignFirstResponder()
            tagContainerView.isHidden = false
        }
        
        return true
    }
    
}
