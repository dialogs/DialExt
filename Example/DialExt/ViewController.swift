//
//  ViewController.swift
//  DialExt
//
//  Created by Vladlex on 03/10/2017.
//  Copyright (c) 2017 Vladlex. All rights reserved.
//

import UIKit
import Pods_DialExt
import DialExt

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var dialogs: [Dialog] = []
    
    let container = DEGroupContainer.init(groupId: "group.im.dlg.DialExtApp")
    
    @IBOutlet public var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For test
        
        let dialogRep = Dialog.getBuilder()
        dialogRep.title = "123"
        dialogRep.id = 123456789
        dialogRep.uid = [1]
        let dialog = try! dialogRep.build()
        
        dialogs = [dialog]
        
        let item = container.item(forFileNamed: "Test")
        let data = "data".data(using: .utf8)!
        item.writeData(data, onFinish: { success, error in
            guard success else {
                print("Fail: \(error)")
                return
            }
            print("success!")
        })
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dialogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCell(withIdentifier: "DialogCell", for: indexPath) as! DialogCell
        let dialog = dialogs[indexPath.row]
        cell.nameLabel.text = dialog.title
        return cell
    }
}

