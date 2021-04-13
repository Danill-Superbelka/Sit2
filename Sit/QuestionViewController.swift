//
//  QuestionViewController.swift
//  Sit
//
//  Created by Даниил  on 24.02.2021.
//

import UIKit
import RealmSwift

class qtCellView: UITableViewCell {
    
    @IBOutlet var ruleText: UILabel!
    
}


class QuestionViewController: UITableViewController{
    weak var delegate: ResultViewController?
    let headerId = String(describing: CustomHeaderView.self)
    let user = app.currentUser!
    let org: Organization
    var ruleMass = [Int]()
    var answer = [Int]()
    

    required init?(coder: NSCoder, org: Organization) {
        
        self.org = org
        super.init(coder: coder)
        if org.answer.count != 0 {
            self.answer = org.answer.components(separatedBy: ",").compactMap{Int($0)}
            print("Ответы из MongoDb: \(answer) ")
        } else {
            self.answer = [Int]()
            print("Новый массив ответов")
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(result))
        tableViewConfig()
        takeInf(org: org)
        
        
    }
    
    private func takeInf(org:Organization){
        var configuration = user.configuration(partitionValue: org.protectionClass)
        configuration.objectTypes = [rulesOfType.self]
        Realm.asyncOpen(configuration: configuration) { [self] (result) in
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error.localizedDescription)")
            case .success(let realm):
                print("Successfully opened realm:\(realm)")
                let rul = realm.objects(rulesOfType.self)
                let stringRule = rul[0].rules
                self.ruleMass = self.get_numbers(stringtext: stringRule)
                
                
            }
        }
    }
    
    func get_IntMass(intmass: [String]) -> [Int]{
        var numberMass:[Int] = []
        for i in 0...intmass.count - 1{
            let number = Int(intmass[i])
            numberMass.append(number ?? 0 )
            print(numberMass)
        }
        return numberMass
    }
    
    // MARK: - Table view data source
    private func tableViewConfig(){
        let nib = UINib(nibName: headerId, bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: headerId)
        tableView.tableFooterView = UIView()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return rulesCount.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if !rulesCount[section].isExpanded {
            return 0
        }
        return rulesCount[section].rulesBlock.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! qtCellView
        let mySwitch = UISwitch()
        mySwitch.tag = Int("\(indexPath.section + 1)\(indexPath.row + 1)")!
        cell.ruleText?.numberOfLines = 0
        cell.ruleText?.text = rulesCount[indexPath.section].rulesBlock[mySwitch.tag]
        mySwitch.addTarget(self, action: #selector(chage), for: .valueChanged)
        if answer.contains(mySwitch.tag){
            mySwitch.isOn = true
        } else { mySwitch.isOn = false}
        cell.accessoryView = mySwitch
        return cell
    }
    
    
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerId) as! CustomHeaderView
        
        header.configure(title: rulesCount[section].title, section: section)
        header.rotateImage(rulesCount[section].isExpanded)
        header.delegate = self
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func get_numbers(stringtext:String) -> [Int] {
        let StringRecordedArr = stringtext.components(separatedBy: ",")
        return StringRecordedArr.map { Int($0)!}
    }
        
    @objc func chage(sender: UISwitch){
        if sender.isOn {
            answer.append(sender.tag)
        } else{
           answer = answer.filter {$0 != sender.tag}
        }
        print("Tag: \(sender.tag), Answer: \(answer)")
    }
    
    @objc func result(){
        let ruleMassSet = Set(ruleMass)
        let answerSet = Set(answer)
        let need = ruleMassSet.subtracting(answerSet).sorted()
        let dontNeed = answerSet.subtracting(ruleMassSet).sorted()
        let resultPercentage = (Int(Double(answerSet.count)/Double(ruleMassSet.count)*100))
        delegate?.update(need: need, dontNeed: dontNeed)
        
        
        let predicate = NSPredicate(format: "name == %@", "\(org.name)")
        var configuration = user.configuration(partitionValue: "org = \(user.id)")
        configuration.objectTypes = [Organization.self]
        
        Realm.asyncOpen(configuration: configuration) { (result) in
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error.localizedDescription)")
            case .success(let realm):
                print("Successfully opened realm:\(realm)")
                let orgNeed = realm.objects(Organization.self)
                let orgFilter = orgNeed.filter(predicate)
                let currentOrg = orgFilter[0]

                try! realm.write{
                    currentOrg.answer = self.answer.map{String(describing: $0)}.joined(separator: ",")
                    currentOrg.percentage = String("\(resultPercentage)")
                    currentOrg.needRuleOrg = need.map{String(describing: $0)}.joined(separator: ",")
                    currentOrg.dontNeedRuleOrg = dontNeed.map{String(describing: $0)}.joined(separator: ",")
                }
            }
        }
    }
    
    func Show(){
        guard let vc = storyboard?.instantiateViewController(identifier: "ResultVC", creator: {
            coder in return QuestionViewController(coder: coder)
        }) else {
            fatalError("Failed to load OrgTableViewController")
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension QuestionViewController: HeaderViewDelegate{
    func expandedSection(button: UIButton) {
        let section = button.tag
        
        let isExpanded = rulesCount[section].isExpanded
        rulesCount[section].isExpanded = !isExpanded
        
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
}
