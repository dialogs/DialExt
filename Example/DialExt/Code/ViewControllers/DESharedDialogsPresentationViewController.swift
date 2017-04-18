//
//  DESharedDialogsPresentationViewController.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 17/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public enum FakeError: Error {
    case noError
}

open class DESharedDialogsPresentationViewController: UIViewController,
DESharedDialogsViewControllerExtensionContextProvider {
    
    /// Override value in your subclass
    open var config: DESharedDataConfig! {
        return nil
    }
    
    private var dialogsController: DESharedDialogsViewController? = nil
    
    private var navController: UINavigationController? = nil
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        let dialogsController = DESharedDialogsViewController.createFromDefaultStoryboard(config: self.config)
        dialogsController.extensionContextProvider = self
        self.dialogsController = dialogsController
        
        let navController = UINavigationController(rootViewController: dialogsController)
        self.navController = navController
        
        self.dialogsController?.onDidFinish = { [unowned self] in
            if let context = self.extensionContext {
                self.navController!.dismiss(animated: true, completion: {
                    context.cancelRequest(withError: FakeError.noError)
                })
            }
        }
        
        self.present(navController, animated: true, completion: nil)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    public func extensionContextForSharedDialogsViewController(_ viewController: DESharedDialogsViewController) -> NSExtensionContext? {
        return self.extensionContext
    }
}
