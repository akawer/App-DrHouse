//
//  LoginController.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/2/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit

import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import SwiftKeychainWrapper

// REMEMBER ADD ALERTS WHEN ERRORS

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //if having issues in tableView didSelectRow uncomment this
        //tap.cancelsTouchesInView = false
    }
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

class LoginController: UIViewController {
    
    @IBOutlet weak var emailField: UpgradedField!
    @IBOutlet weak var pwdField: UpgradedField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // to hide keyboward in every UIViewController, all you have to do is call this function
        self.hideKeyboardWhenTappedAround()
 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            print("NEGROKO: ID found in Keychain")
            performSegue(withIdentifier: "goToFeed", sender: nil)
        }
    }
    
    // maybe delete this function to avoid unnecessary warnings
    override func didReceiveMemoryWarning() {
        super.viewDidLoad()
        //Do any additional bla bla
    }
    // MARK: - Functions
    
    @IBAction func facebookBtnTapped(_ sender: Any) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("NEGROKO: Unable to authenticate with Facebook - \(error)")
            } else if result?.isCancelled == true {
                print("NEGROKO: User cancelled Facebook authentication")
            } else {
                print("NEGROKO: Successfully authenticated with Facebook \n")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("NEGROKO: Unable to authenticate with Firebase - \(error)")
            } else {
                print("NEGROKO: Successfully authenticated with Firebase")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: user.uid, userData: userData)
                }
            }
        })
    }
    
    
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = pwdField.text {
            // set alert here if needed to in Final app
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("NEGROKO: Email user authenticated with Firebasse")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("NEGROKO: Unable to authenticate with Firebasse using email")
                        } else {
                            print("NEGROKO: Successfully authenticated with Firebasse")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignIn(id: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
}
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createdFireBaseDBUser(uid: id, userData: userData)
        let keychainResult = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("NEGROKO: Data saved to Keychain \(keychainResult)")
        
        // Check the user name
        DataService.ds.REF_USERS.child(id).child("username").observeSingleEvent(of: .value, with: {
            snapshot in
            // If the username has been already set
            if let _ = snapshot.value as? String {
                // Go to the feed
                self.performSegue(withIdentifier: "goToFeed", sender: nil)
            } else {
                // Else make the user fill their profile
                self.performSegue(withIdentifier: "goToEditProfile", sender: nil)
            }
        })
    }
    
}
