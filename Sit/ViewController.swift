//
//  ViewController.swift
//  Sit
//
//  Created by Даниил  on 12.01.2021.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var email: String? {
        get {
            return emailTextField.text
        }
    }
    
    var password: String? {
        get {
            return passwordTextField.text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settings()
        self.hideKeyboardWhenTappedAround()
        
        
        
    }
        
    @objc func settings(){
        signInButton.addTarget(self, action: #selector(signIn), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)
        activityIndicator.isHidden = true
    }

    @objc func setLoading(_ loading:Bool){
        if loading {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
        emailTextField.isEnabled = !loading
        passwordTextField.isEnabled = !loading
        signInButton.isEnabled = !loading
        signUpButton.isEnabled = !loading
    }
    
    @objc func signIn(){
        setLoading(true)
        app.login(credentials: Credentials.emailPassword(email: email!, password: password!)) { [weak self](result) in
           
            DispatchQueue.main.async {
               self!.setLoading(false)
                switch result {
                case .failure(let error):
                    self!.errorLabel.text = "Login failed: \(error.localizedDescription)"
                    return
                case .success(let user):
                    print("Login succeeded!");
                    self!.setLoading(true)
                    var configuration = user.configuration(partitionValue: "user=\(user.id)")
                    configuration.objectTypes = [User.self]
                    Realm.asyncOpen(configuration: configuration) { [weak self](result) in
                       
                        DispatchQueue.main.async {
                           self!.setLoading(false)
                            switch result {
                            case .failure(let error):
                                fatalError("Failed to open realm: \(error)")
                            case .success(let userRealm):
                                self!.Show(userRealm: userRealm)

                            }
                        }
                    }
                }
            }
        };
    }
    
    @objc func signUp(){
        if emailTextField.text?.isEmpty == true || passwordTextField.text?.isEmpty == true {
            errorLabel.text = "Поля не заполнены"
        } else {
            setLoading(true)
            app.emailPasswordAuth.registerUser(email: email!, password: password!, completion: { [weak self](error) in
                
                DispatchQueue.main.sync {
                    self!.setLoading(false)
                    guard error == nil else {
                        print("Signup failed: \(error!)")
                        self!.errorLabel.text = "Signup failed: \(error!.localizedDescription)"
                        return
                    }
                    self!.errorLabel.text = "Успешно! Вход..."
                    self!.addUser(email: self!.email!)
                    self!.signIn()
                }
            })
        }
    }
    
    @objc func addUser(email : String){
        let user = app.currentUser!
        let partitionValue = "user=\(user.id)"
        var configuration = user.configuration(partitionValue: partitionValue)
        configuration.objectTypes = [User.self]
        
        Realm.asyncOpen(configuration: configuration) { (result) in
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error.localizedDescription)")
            case .success(let realm):
                let userAdd = User.init(partition: partitionValue, name: email, emailUser: "Имя")
                try! realm.write{
                    realm.add(userAdd)
                    print("Пользователь добавлен")
                }
            }
        }
    }
    
    func Show(userRealm: Realm) {
        guard let vc = storyboard?.instantiateViewController(identifier: "ProjectsVController", creator: {coder in
                return ProjectsViewController(coder: coder, userRealm: userRealm)
        }) else {
            fatalError("Failed to load ProjectsViewController")
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


