//
//  EditProfileVC.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/18/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit
import Firebase

class EditProfileVC : UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // -------------------------
    // MARK - Properties
    // -------------------------
    
    @IBOutlet weak var imageAdd: CircularView!
    @IBOutlet weak var usernameTextField: UITextField!
    
    // -------------------------
    // MARK - Properties
    // -------------------------
    
    var imageSelected = false
    var imagePicker: UIImagePickerController!
    
    // -------------------------
    // MARK - Lifecycle
    // -------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        

        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        loadUserData()
    }
    
    func loadUserData() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let firebasePost = DataService.ds.REF_USERS.child(uid)
        firebasePost.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                DispatchQueue.main.async {
                    self.usernameTextField.text = value["username"] as? String
                    
                    // Load the image from firebase url
                    if let url = value["imageUrl"] as? String {
                        self.imageAdd.setImage(firebaseURL: url)
                    }
                }
            }
        })
    }
    
    
    @IBAction func doneTapped(_ sender: Any) {
        
        // When the user goes to a different screen, save the data
        save()
        
        // If there is a feed already underneath, just dismiss the settings
        if let _ = presentingViewController as? FeedVC {
            dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "showFeed", sender: nil)
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
    
    
    func save() {
        guard let caption = usernameTextField.text, caption != "" else {
            print("NEGROKO: Caption must be entered")
            return
        }
        
        guard let img = imageAdd.image, imageSelected == true else {
            print("NEGROKO: An image must be selected")
            self.postToFirebase(imgUrl: nil)  // Post without an image
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
    
    func postToFirebase(imgUrl: String?) {
        
        // Make sure the user is logged in
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userData = [
            "username": usernameTextField.text!,
            "userId" : uid
        ]
        
        if let url = imgUrl {
            userData["imageUrl"] = url
        }
        
        let firebasePost = DataService.ds.REF_USERS.child(uid)
        firebasePost.updateChildValues(userData)
        
        usernameTextField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
    }

    
}
