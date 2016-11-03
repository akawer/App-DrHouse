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


class LoginController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()

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
            }
            })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
