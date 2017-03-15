//
//  DESharedDialogsViewController.swift
//  DialExt
//
//  Created by Vladlex on 03/10/2017.
//  Copyright (c) 2017 Vladlex. All rights reserved.
//

import UIKit

open class DESharedDialogsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    static public func createFromDefaultStoryboard() -> DESharedDialogsViewController {
        let bundle = Bundle(for: self )
        let storyboard = UIStoryboard(name: "DESharedDialogsViewController", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! DESharedDialogsViewController
        return controller
    }
    
    var dialogs: [Dialog] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    let manager = DESharedDialogsManager.init(groupContainerId: "group.im.dlg.DialExtApp",
                                              keychainGroup: "")
    private let image: UIImage? = UIImage(named: "gp_chat")
    
    private var shareController: UIActivityViewController? = nil
    
    @IBOutlet public var tableView: UITableView!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.manager.onDidChangeDialogsState = { [weak self] state in
            withExtendedLifetime(self){
                guard self != nil else { return }
                self!.handleDialogsState(state)
            }
        }
        self.manager.start()
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func handleDialogsState(_ state: DESharedDialogsManager.DialogsState) {
        switch state {
        case let .failed(error):
            fatalError("Totally failed: \(error)")
            
        case .loaded:
            self.dialogs = self.manager.context!.dialog
            
        default:
            break
        }
    }
    
    private func isLastRow(at: IndexPath) -> Bool {
        return at.row == self.dialogs.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dialogs.count + 1
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isLastRow(at: indexPath) ? 88.0 : 44.0
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isLastRow(at: indexPath) {
            let controller = UIActivityViewController.init(activityItems: [self.image],
                                                           applicationActivities: nil)
            self.present(controller, animated: true, completion: nil)
            self.shareController = controller
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isLastOne = isLastRow(at: indexPath)
        if isLastOne {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DEImageToShareCell", for: indexPath) as! DEImageToShareCell
            cell.imageToShareView.image = self.image
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DEDialogCell", for: indexPath) as! DEDialogCell
            let dialog = dialogs[indexPath.row]
            cell.nameLabel.text = dialog.title
            return cell
        }
    }
}

