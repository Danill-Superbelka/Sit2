//
//  CreateViewController.swift
//  Sit
//
//  Created by Даниил  on 20.01.2021.
//

import UIKit
import RealmSwift

class CreateViewController: UIViewController {
    
    let realm: Realm
    let organization: Results<Organization>
    let partitionValue: String
    var notificationToken: NotificationToken?
    @IBOutlet var orgNameLabel: UITextField!
    @IBOutlet var typeOfData: UISegmentedControl!
    @IBOutlet var numberOfData: UISegmentedControl!

    required init?(coder: NSCoder,realm: Realm, title: String) {
        guard let syncConfiguration = realm.configuration.syncConfiguration else {
            fatalError("Sync configuratfgdion not found! Realm not opened with sync?");
        }
        self.realm = realm
        partitionValue = syncConfiguration.partitionValue!.stringValue!
        organization = realm.objects(Organization.self).sorted(byKeyPath: "_id")
        super.init(coder: coder)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Always invalidate any notification tokens when you are done with them.
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Добавить", style: .done, target: self, action: #selector(addOrganization))

        // Do any additional setup after loading the view.
    }
    
    @objc func addOrganization() {
        let classOfOrg: Int
        let result = "\(typeOfData.selectedSegmentIndex + 1)\(numberOfData.selectedSegmentIndex + 1)"
        switch result {
        case "22":
            classOfOrg = 2
        case "23":
            classOfOrg = 3
        case "31":
            classOfOrg = 2
        case "32":
            classOfOrg = 3
        case "33":
            classOfOrg = 3
        case "41":
            classOfOrg = 4
        case "42":
            classOfOrg = 4
        case "43":
            classOfOrg = 4
        default:
            classOfOrg = 1
        }
        let org = Organization(partition: self.partitionValue, name: orgNameLabel.text!, protectionClass: String(classOfOrg), percentage: String("0%"))
        try! self.realm.write{
            self.realm.add(org)
        }
    }
    
    
    
    
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
