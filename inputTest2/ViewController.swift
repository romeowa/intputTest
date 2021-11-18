//
//  ViewController.swift
//  inputTest2
//
//  Created by howard on 2021/10/27.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var myInputView: UITextView!
    @IBOutlet weak var myTableView: UITableView!
    
    struct Item: Hashable {
        var id:Int64
        var text = ""
        var placeId:Int64
        var isSelected = false
    }
    
    class InputText {
        init(text: String) {
            self.text = text
        }
        var text: String
        var searched = false
        var items = [Item]()
    }
    
    var sets = NSOrderedSet()
    var inputTexts = [InputText]()
    var oldTexts = [String]()
    var testData = [TestRecord]()
    var testDic = [String: TestRecord]()
    
    var result = [Any]()
    
    private var debouncer = Debouncer(minimumDelay: 0.5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myInputView.delegate = self
        myTableView.delegate = self
        myTableView.dataSource = self
        print("begin\t\t\(Date.init(timeIntervalSinceNow: 0))")
        if let records = loadJsonFile() {
            print("jsonLoaded\t\(Date.init(timeIntervalSinceNow: 0))")
            TestDatabase.shared.insert(records: records)
            print("insert all\t\(Date.init(timeIntervalSinceNow: 0))")
        } else {
            print("insert fail\t\t\(Date.init(timeIntervalSinceNow: 0))")
        }
        
        let fetchedRecords = TestDatabase.shared.fetchAll()
        print("fetched\t\t\(Date.init(timeIntervalSinceNow: 0))")
        
        for record in fetchedRecords {
            testDic[record.word] = record
        }
        print("map made\t\(Date.init(timeIntervalSinceNow: 0)) count: \(testDic.count)")
    }
    
    func loadJsonFile() -> [TestRecord]?{
        let jsongDecoder = JSONDecoder()
        
        do {
            guard let path = Bundle.main.url(forResource: "sampleData2", withExtension: "json")  else { return nil }
            let jsonData = try Data(contentsOf: path, options: .mappedIfSafe)
            let decodedBigSur = try jsongDecoder.decode([TestRecord].self, from: jsonData)
            return decodedBigSur
        }
        catch {
            print(error)
            return nil
        }
    }
    
    func saveJsonData(data:[TestRecord]) {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = JSONEncoder.OutputFormatting.prettyPrinted
        
        do {
            let encodedData = try jsonEncoder.encode(data)
            guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileURL = documentDirectoryUrl.appendingPathComponent("sampleData2.json")
            
            do {
                try encodedData.write(to: fileURL)
            }
            catch let error as NSError {
                print(error)
            }
            
        } catch {
            print(error)
        }
        
    }
    
}






extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
        debouncer.debounce { [weak self] in
            guard let self = self else { return }
            if let seperatedItems = NSOrderedSet(array: textView.text.components(separatedBy: CharacterSet.whitespacesAndNewlines).map({ text in
                text.lowercased()
            })).array as? [String] {
                let diff =  seperatedItems.difference(from: self.oldTexts)
                
                for i in (0 ..< diff.removals.count).reversed() {
                    if case let .remove(offset, _, _) = diff.removals[i] {
                        self.inputTexts.remove(at: offset)
                    }
                }
                
                for case let .insert(offset, element, _) in diff.insertions {
                    let inputText = InputText(text: element)
                    self.inputTexts.insert(inputText, at: offset)
                }
                
                self.oldTexts = seperatedItems
            } else {
                self.inputTexts.removeAll()
            }
            
            
            self.updateResult()
            self.myTableView.reloadData()
        }
    }
    
    func updateResult() {
        let tempSet = NSMutableOrderedSet() // Item Set
        print("--------------------------------------")
        self.inputTexts.forEach({ inputText in
            if inputText.searched == true {
                for item in inputText.items {
                    print("cached: \(item.text)")
                    tempSet.add(item)
                }
            } else {
                let str = inputText.text
                inputText.searched = true
                print("second: \(str)")
                if str.count > 1 {
                    let count = str.count - 1
                    for i in (0 ..< count) {
                        let length = str.count - i
                        for j in (1 ..< length) {
                            let subText = str[str.index(str.startIndex, offsetBy: i) ... str.index(str.startIndex, offsetBy: (i + j))]
                            if let record = testDic[String(subText)] {
                                let item = Item(id: record.id!,text: String(subText), placeId: record.placeId, isSelected: false)
                                print("parse = \(item.text)")
                                inputText.items.append(item)
                                tempSet.add(item)
                            }
                        }
                    }
                }
            }
        })
        
        print("tempSet: \(tempSet)")
        self.result = tempSet.array
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if let item = result[indexPath.row] as? Item {
            cell.textLabel?.text = "\(item.text) - \(item.placeId)"
        }
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if var item = result[indexPath.row] as? Item {
            item.isSelected = true
        }
    }
}
