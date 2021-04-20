//
//  OrgTableViewController.swift
//  Sit
//
//  Created by Даниил  on 20.01.2021.
//

import UIKit
import RealmSwift

class OrganizationCellView: UITableViewCell{
    
    @IBOutlet var orgNameLabel: UILabel!
    @IBOutlet var orgPerBar: UIProgressView!
    @IBOutlet var orgPerLabel: UILabel!
}

class OrgTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    let partitionValue: String
    let realm: Realm
    var notificationToken: NotificationToken?
    let organization: Results<Organization>
    
    required init?(coder: NSCoder,realm: Realm, title: String) {

        guard let syncConfiguration = realm.configuration.syncConfiguration else {
            fatalError("Sync configuration not found! Realm not opened with sync?");
        }
        self.realm = realm
        partitionValue = syncConfiguration.partitionValue!.stringValue!
        organization = realm.objects(Organization.self).sorted(byKeyPath: "_id")

        super.init(coder: coder)

        self.title = title
        
        notificationToken = organization.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.performBatchUpdates({
                    tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                    tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                    tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                })
            case .error(let error):
                fatalError("\(error)")
            }
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
    
    @objc func settings() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidClick))
    }
  
    @objc func addButtonDidClick() {
        let user = app.currentUser!
        Realm.asyncOpen(configuration: user.configuration(partitionValue: "org = \(user.id)")) { [weak self] (result) in
            switch result {
            case .failure(let error):
                fatalError("Failed to open realm: \(error)")
            case .success(let realm):
                self!.ShowCreateVC(realm: realm, title: "Добавить оргнаизацию")
                ;}}
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if organization.count == 0 {
            let alert = UIAlertController(title: "Организаций нет", message: "Хотите добавить организацию?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Добавить", style: UIAlertAction.Style.default, handler: { action in self.addButtonDidClick()}))
            alert.addAction(UIAlertAction(title: "Нет", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        return organization.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let organizations = organization[indexPath.row]
        let percent = Float(organizations.percentage) ?? 0
        let cell = tableView.dequeueReusableCell(withIdentifier: "orgCell", for: indexPath) as! OrganizationCellView
        cell.orgNameLabel?.text = organizations.name
        cell.orgPerBar?.progress = percent / 100
        cell.orgPerLabel?.text = "\(organizations.percentage)%"
        cell.layer.borderWidth = CGFloat(5)
        cell.layer.borderColor = tableView.backgroundColor?.cgColor
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let org = organization[indexPath.row]
        self.Show(org: org)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let task = organization[indexPath.row]
        try! realm.write {
            realm.delete(task)
        }
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
// Удалить
//    func isOwnTasks() -> Bool {
//        return partitionValue == "project=\(app.currentUser!.id)"
//    }
    
    func ShowCreateVC(realm: Realm, title: String){
        print("Функция открытия контроллера")
        guard let vc = storyboard?.instantiateViewController(identifier: "CreateVC", creator: {
            coder in return CreateViewController(coder: coder, realm: realm, title: title)
        }) else {
            fatalError("Failed to load OrgTableViewController")
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    func Show(org: Organization){
        guard let vc = storyboard?.instantiateViewController(identifier: "ResultVC", creator: {
            coder in return ResultViewController(coder: coder, org: org)
        }) else {
            fatalError("Failed to load OrgTableViewController")
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}





