//
//  HomeScreen.swift
//  BookSwap
//
//  Created by RV on 10/5/19.
//  Copyright © 2019 RV. All rights reserved.
//

import UIKit
import Firebase
//import SVProgressHUD


class HomeScreen: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func logInBtnPressed(_ sender: Any) {
    
        
        
        if (checkIfTextFieldIsEmpty()){
            //Log in the user
            //SVProgressHUD.show()
            Auth.auth().signIn(withEmail: userNameTextField.text!, password: passwordTextField.text!) { (user , error) in
                
                if (error != nil){
                    print(error!)
                    //SVProgressHUD.dismiss()
                } else{
                    print("Log in Successful!")
                    //SVProgressHUD.dismiss()
                    
                    self.performSegue(withIdentifier: "toProfileScreen",  sender: self)
                }
            }
        } 
    }
    
    
    //Same as Sign Up Screen function.
    func checkIfTextFieldIsEmpty() -> Bool {
        
        let userNameCheckStatus = checkIfEmpty(userNameTextField, "User Name")
        let passwordCheckStatus =  checkIfEmpty(passwordTextField, "Password")
        
        return userNameCheckStatus && passwordCheckStatus
    }
    
    
    func checkIfEmpty(_ textField: UITextField,_ paceholderText: String) -> Bool{
        
        if textField.text!.isEmpty {
            //Making changes to inform user that text field is empty
            textField.attributedPlaceholder = NSAttributedString(string: paceholderText,
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
            //textField.backgroundColor = UIColor.red
            return false
            
        }else{
            
            // Revert the changes made in if statment
            textField.backgroundColor = UIColor.white
            return true
            
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "toProfileScreen"{
//
//            let destinationScreen = segue.destination as! ProfileScreen
//
//            destinationScreen.userNameReciver = userNameLbl.text!
//
//        }
//    }
//
    @IBAction func unwindToHomeScreen(_ sender: UIStoryboardSegue){}
    
}
