//
//  DialogsController.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DialExt


extension DESharedDialogsViewController {
    
    func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                        target: self,
                                        action: #selector(addDialogAction(sender:)))
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    @objc private func addDialogAction(sender: AnyObject) {
        
        if let context = self.manager.dataLoader.context {
            let contextBuilder = try! context.toBuilder()
            let dialogBuilder = AppSharedDialog.getBuilder()
            dialogBuilder.title = UUID.init().uuidString
            dialogBuilder.isGroup = false
            dialogBuilder.uids = []
            dialogBuilder.id = Int64(arc4random())
            let dialog = try! dialogBuilder.build()
            
            contextBuilder.dialogs.insert(dialog, at: 0)
            
            let newContext = try! contextBuilder.build()
            
            self.manager.dataLoader.contextQueuer.put(representation: newContext)
            self.resetDialogs(newContext.dialogs)
        }
    }
}
