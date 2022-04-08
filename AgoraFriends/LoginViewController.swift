//
//  LoginViewController.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 07/04/2022.
//

import Foundation

import UIKit

// MARK: - UserInfo

struct UserInfo: Codable {
    let email: String
    let password: String
}

private var users: [UserInfo] = []

// MARK: - LoginViewController
class LoginViewController: UIViewController, ShowAlertProtocol {
    @IBOutlet private weak var emailField: UITextField!
    @IBOutlet private weak var passwordField: UITextField!
    let userDefaults = UserDefaults.standard

    
    override func viewDidLoad() {
            super.viewDidLoad()
         }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @IBAction private func registerAction(_ sender : Any){
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let loginController = storyBoard.instantiateViewController(withIdentifier: "RegisterVC")
        loginController.modalPresentationStyle = .fullScreen
        self.present(loginController, animated: true, completion: nil)
    }

    @IBAction private func loginAction(_ sender: Any) {
        if !isValidEmail(emailField.text!) {
            self.showAlert("Enter a valid email address")
        }
        
        if passwordField.text!.count<5 {
            self.showAlert("Password must be atleast 8 characters")
            return
        }
        
        guard let username = emailField.text else {
            emailField.becomeFirstResponder()
            self.showAlert("Enter Valid Email Address")
            return
        }
        guard let password = passwordField.text else {
            passwordField.becomeFirstResponder()
            self.showAlert("Enter Valid Password")
            return
        }
        
        loginAPI(email: username, password: password)
 
        self.view.endEditing(true)
        
      
    }
    
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func loginAPI(email: String, password: String) {
        
        let api = RESTHandler<FriendsService>()

        api.load(REST: .login(email: email, password: password)) { result in
            switch result {
            case .success(let resp):
                print(resp)
                let stringValue = String(decoding: resp, as: UTF8.self)
                let dict : [String: Any]? = self.convertToDictionary(text: stringValue)
                
                if let val = dict?["error"] {
                    DispatchQueue.main.async {
                        self.showAlert(val as! String)
                    }
                }
                
                if let val = dict?["token"] {
                    self.userDefaults.setisLoggedIn(value: true)
                    self.userDefaults.setUserId(value: dict?["_id"] as! Int)
                    self.userDefaults.setUserName(value: dict?["name"] as! String)
                    self.userDefaults.setUserEmail(value: dict?["email"] as! String)

                    self.userDefaults.setToken(value: val as! String)
                    DispatchQueue.main.async {
                        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                        
                    }
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    
                }
            case .empty:
                print("No data")
            }
        }
    }

}

// MARK: - LoginViewController extensions
extension LoginViewController  {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}
