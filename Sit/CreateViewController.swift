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
    @IBOutlet var typeOfThreads: UISegmentedControl!
    @IBOutlet var whoseData: UISegmentedControl!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var testBut: UIButton!
    
    required init?(coder: NSCoder,realm: Realm, title: String) {
        guard let syncConfiguration = realm.configuration.syncConfiguration else {
            fatalError("Sync configuratfgdion not found! Realm not opened with sync?");
        }
        self.realm = realm
        partitionValue = syncConfiguration.partitionValue!.stringValue!
        organization = realm.objects(Organization.self)
        super.init(coder: coder)
        self.title = title
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
        self.hideKeyboardWhenTappedAround()
    }
    
    @objc func settings(){
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Добавить", style: .done, target: self, action: #selector(addOrganization))
        addButton.layer.cornerRadius = 10
        addButton.addTarget(self, action: #selector(addOrganization), for: .touchUpInside)

    }
    
    @objc func addOrganization() {
        let classOfOrg: String
        let result = "\(typeOfData.selectedSegmentIndex + 1)\(whoseData.selectedSegmentIndex + 1)\(numberOfData.selectedSegmentIndex + 1)\(typeOfThreads.selectedSegmentIndex + 1)" // Тип данных, Данные сотрудников/внешних лиц, Объем данных, Типы угроз
    
        switch result {
        case "1221","1211","1111","1121","2111","2211","1222","4221","4211","4111","4121":
            classOfOrg = "1"
        case "3221","3211","3111","3121","1212","1112","1122","2112","2122","2212","2222","3222","4222","1223":
            classOfOrg = "2"
        case "3212","3112","3122","4212","4112","4122","1213","1113","1123","2113","2123","2213","2223","4223":
            classOfOrg = "3"
        case "3223","3213","3113","3123","4213","4113","4123":
            classOfOrg = "4"
        default:
            classOfOrg = "0"
        }
        
        let org = Organization(partition: partitionValue, name: orgNameLabel.text!, protectionClass: classOfOrg, percentage: "0", preferences: "", answer: "", needRuleOrg: "")
        try! self.realm.write{
            self.realm.add(org)
        }
    }
}
