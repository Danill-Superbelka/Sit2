//
//  ResultViewController.swift
//  Sit
//
//  Created by Даниил  on 05.03.2021.
//

import UIKit
import RealmSwift
import Charts

protocol ResultVCDelegate: class {
//    func update(need:[Int], dontNeed:[Int], preferDict: [Int:Int])
    func update(need:[Int], dontNeed:[Int])

}


class ResultVCCell: UITableViewCell {
    
    @IBOutlet var textLabelRule: UILabel!
    @IBOutlet var preferencLabel: UILabel!
    @IBOutlet weak var stepperBut: UIStepper!
    
}
   
    


class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let user = app.currentUser!
    let org: Organization
    var needRule: [Int]
    var numberBlock = [Int]()
    var preferencesArr = [Int]()
    var dictPref = [Int:Int]()
    var dataPoint = [String]()
    var keyMass2 = [Int]()

    @IBOutlet var orgNameLabel: UILabel!
    @IBAction func qtVCButton(_ sender: Any) {
        showQtVC(org: org)
    }
    @IBOutlet var resultTVC: UITableView!
    @IBOutlet var chartView: BarChartView!
    
    required init?(coder: NSCoder, org: Organization) {
        self.org = org
        self.needRule = org.needRuleOrg.components(separatedBy: ",").compactMap{Int($0)}
        print("Need Rule: ", needRule)
        self.preferencesArr = org.preferences.components(separatedBy: ",").compactMap{Int($0)}
        if self.preferencesArr.isEmpty {
//            fatalError("Коэффициенты не найдены")
            print("Коэффициенты не найдены")
        }
        var keyMass = [Int]()
        rulesCount.forEach { rule in
            keyMass += rule.rulesBlock.keys.sorted()
        }
        self.keyMass2 = keyMass
        let seq = zip(keyMass, self.preferencesArr)
        self.dictPref = Dictionary(uniqueKeysWithValues: seq)
        
        super.init(coder: coder)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settings()
        self.resultTVC.delegate = self
        self.resultTVC.dataSource = self

//        for i in 0..<numberBlock.count {
//            dataPoint.append(rulesCount[numberBlock[i] - 1].rulesBlock[needRule[i]] ?? "Правило не найдено")
//        }
//        print("DataPoint: \(dataPoint)")
//       // customizeChart(dataPoints: dataPoint, values: preferencArr.map{Double($0)} )
    }
    
    @objc func settings(){
        orgNameLabel?.text = org.name
        self.resultTVC.delegate = self
        self.resultTVC.dataSource = self
        
        if needRule.isEmpty {
            print("Задач нет")
        } else{
            needRule.forEach { element in
                switch element{
                case 210,211,212,213,214,215,216,217:
                    numberBlock.append(element.digits[0])
                default:
                    if element > 100 {
                        numberBlock.append(Int("\(element.digits[0])"+"\(element.digits[1])")!)
                        
                    } else {
                        numberBlock.append(element.digits[0])      
                    }
                }
                
            }
        }
        print("Number Block:", numberBlock)

        numberBlock.forEach{ element in
            dataPoint.append(rulesCount[numberBlock[element]].rulesBlock[needRule[element]] ?? "Правило не найдено")
        }
        customizeChart(dataPoints: dataPoint, values: preferencesArr.map{Double($0)} )
    }
        
    func customizeChart(dataPoints: [String], values: [Double]) {
        chartView.noDataText = "Нет необходимых правил"
        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(values[i]))
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(entries:dataEntries, label: "bar Chart View")
        chartDataSet.colors = colorsOfCharts(numberColor: dataPoints.count, valueColor: values)
        let chartData = BarChartData(dataSet: chartDataSet)
        
        chartView.data = chartData
    }
    
    private func colorsOfCharts(numberColor: Int, valueColor: [Double]) -> [UIColor]{
        var colors: [UIColor] = []
        for i in 0..<numberColor{
            if valueColor[i] <= 5 {
                colors.append(UIColor.green)
            } else if valueColor[i] <= 7{
                colors.append(UIColor.yellow)
            } else {
                colors.append(UIColor.red)
            }
        }
        return colors
    }
    
    
    
    func update(need:[Int], dontNeed:[Int]){
        self.needRule = need
    }
    
    func showQtVC(org: Organization){
        guard let vc = storyboard?.instantiateViewController(identifier: "QtTVC", creator: {
            coder in return QuestionViewController(coder: coder, org: org)
        }) else {
            fatalError("Failed to load OrgTableViewController")
        }
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return needRule.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellResultVC", for: indexPath) as! ResultVCCell
        cell.textLabelRule?.text = rulesCount[numberBlock[indexPath.row] - 1].rulesBlock[needRule[indexPath.row]]
        let stepperValue = dictPref[needRule[indexPath.row]]
        cell.stepperBut.value = Double(stepperValue ?? 0)
        cell.stepperBut.tag = indexPath.row
        cell.preferencLabel.text = "\(stepperValue ?? 0)"
        return cell
    }
    
    
    @IBAction func stepperValueChanged(_ stepper: UIStepper) {
        let stepperValue = Int(stepper.value)
        let index = stepper.tag
        let indexPath = IndexPath(row: index, section: 0)
        let rule = needRule[index]

        dictPref[rule] = stepperValue
        
        var massValue = [Int]()
        keyMass2.forEach{ element in
            massValue.append(dictPref[element] ?? 0)
        }
        preferencesArr = massValue
        
        let cell: ResultVCCell = resultTVC.cellForRow(at: indexPath) as! ResultVCCell
        cell.preferencLabel.text = "\(stepperValue)"
        customizeChart(dataPoints: dataPoint, values: preferencesArr.map{Double($0)})
        let predicate = NSPredicate(format: "name == %@", "\(org.name)")
        var configuration = user.configuration(partitionValue: "org = \(user.id)")
        configuration.objectTypes = [Organization.self]

        Realm.asyncOpen(configuration: configuration) { (result) in
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error.localizedDescription)")
            case .success(let realm):
                let orgNeed = realm.objects(Organization.self)
                let orgFilter = orgNeed.filter(predicate)
                let currentOrg = orgFilter[0]
                try! realm.write{
                currentOrg.preferences = self.preferencesArr.map{String(describing: $0)}.joined(separator: ",")
                }
            }
        }
    }
        
}
extension StringProtocol {
    var digits: [Int] {
        return compactMap{$0.wholeNumberValue}
    }
}
extension LosslessStringConvertible{
    var string: String { return String(self)}
}
extension Int {
    var digits: [Int] {
        return string.digits
    }
}
    
