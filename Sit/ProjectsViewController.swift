//
//  ProjectsViewController.swift
//  Sit
//
//  Created by Даниил  on 18.01.2021.
//

import UIKit
import RealmSwift
import Foundation

class ProjectsViewController:  UIViewController {
    
    @IBOutlet var nameUserLabel: UILabel!
    @IBOutlet var orgButton: UIButton!
    @IBOutlet var documentButton: UIButton!
    
    var userRealm: Realm
    var notificationToken: NotificationToken?
    var userData: User?
    let user = app.currentUser!
    
    
    init?(coder: NSCoder, userRealm: Realm) {
        self.userRealm = userRealm
        super.init(coder: coder)
        let usersInRealm = userRealm.objects(User.self)
        notificationToken = usersInRealm.observe { [weak self, usersInRealm] (changes) in
            self?.userData = usersInRealm.first
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settings()
        
    }
    
    @objc func settings(){
        orgButton.addTarget(self, action: #selector(openListOrganization), for: .touchUpInside)
        documentButton.addTarget(self, action: #selector(openDocumentTVC), for: .touchUpInside)
        
    }
    
    @objc func openListOrganization(){
        Realm.asyncOpen(configuration: user.configuration(partitionValue: "org = \(user.id)")) { [weak self] (result) in
            switch result {
            case .failure(let error):
                fatalError("Failed to open realm: \(error)")
            case .success(let realm):
                self!.Show(realm: realm, title: "Организации")
            }}
    }
    
    @objc func openDocumentTVC(){
        guard let vc = storyboard?.instantiateViewController(identifier: "DocTVC") else {
            fatalError("Faild to open DocumentTVC")
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func Show(realm: Realm, title: String){
        guard let vc = storyboard?.instantiateViewController(identifier: "OrgTVC", creator: {
            coder in return OrgTableViewController(coder: coder, realm: realm, title: title)
        }) else {
            fatalError("Failed to load OrgTableViewController")
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

