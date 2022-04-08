//
//  SignUpViewController.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 07/04/2022.
//

import Foundation
import UIKit

// MARK: - SignUpViewController
class SignUpViewController: UIViewController, ShowAlertProtocol {
    @IBOutlet private weak var signUpIdTextField: UITextField!
    @IBOutlet private weak var signUpNameTextField: UITextField!
    @IBOutlet private weak var signUpPasswordTextField: UITextField!
    @IBOutlet private weak var signUpVerifyPasswordTextField: UITextField!
    let userDefaults = UserDefaults.standard
    var mandatoryFieldList = [UITextField]()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        mandatoryFieldList = [signUpNameTextField, signUpIdTextField, signUpPasswordTextField, signUpVerifyPasswordTextField]
    }

    @IBAction private func registerAction(_ sender: Any) {

        for field in mandatoryFieldList {
            if !isFilled(field) {
                signUpAlert(field)
                break
            } else{
                guard let name = signUpNameTextField.text else {
                    return
                }
                
                guard let email = signUpIdTextField.text else {
                    return
                }
                
                guard let password = signUpPasswordTextField.text, let passwordCheck = signUpVerifyPasswordTextField.text, password == passwordCheck else {
                    self.showAlert("Make sure passwords are same")
                    return
                }
                
                registerAPI(name: name, email: email, password: password)
            }
        }
        
        func isFilled(_ textField: UITextField) -> Bool {
            guard let text = textField.text, !text.isEmpty else {
                return false
            }
            return true
        }
        
        func signUpAlert(_ field: UITextField) {
            DispatchQueue.main.async {
                var title = ""
                switch field {
                case self.signUpIdTextField:
                    title = "Enter a valid email"
                case self.signUpNameTextField:
                    title = "Enter a valid name"
                case self.signUpPasswordTextField:
                    title = "Password should be atleast 8 characters"
                case self.signUpVerifyPasswordTextField:
                    title = "Repeat password"
                default:
                    title = "Error"
                }
                let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .cancel) { (action) in
                    
                }
                
                controller.addAction(okAction)
                self.present(controller, animated: true, completion: nil)
            }
            return
        }
       
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
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
        
        func registerAPI(name: String, email: String, password: String) {
            let api = RESTHandler<FriendsService>()

            api.load(REST: .register(name: name, email: email, password: password)) { result in
                
                let errorHandle = { [weak self] (action: UIAlertAction) in
                    guard let strongSelf = self else {
                        return
                    }
                    self?.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                }
                
                
                switch result {
                case .success(let resp):
                    print(resp)
                    let stringValue = String(decoding: resp, as: UTF8.self)
                    let dict : [String: Any]? = self.convertToDictionary(text: stringValue)

                    self.userDefaults.setisLoggedIn(value: true)
                    self.userDefaults.setUserName(value: dict?["name"] as! String)
                    let userId : NSNumber = dict?["_id"] as! NSNumber
                    let myInt = userId.intValue
                    self.userDefaults.setUserId(value: myInt)
                    self.userDefaults.setUserEmail(value: dict?["email"] as! String)
                    
                        //On successful registration
                        DispatchQueue.main.async {
                            self.showAlert("Registration success", handler: errorHandle)
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

// MARK: - SignUpViewController extension
extension SignUpViewController {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

}

