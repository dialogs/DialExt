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
DESharedDialogsViewControllerExtensionContextProvider,
DESharedDialogsViewControllerHidingResponsible {
    
    /// Override value in your subclass
    open var config: DESharedDataConfig! {
        return nil
    }
    
    private var dialogsController: DESharedDialogsViewController? = nil
    
    private var navController: UINavigationController? = nil
    
    private var dialogsControllerPresented = false
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let dialogsController = DESharedDialogsViewController.createFromDefaultStoryboard(config: self.config)
        dialogsController.extensionContextProvider = self
        dialogsController.hideResponsible = self
        self.dialogsController = dialogsController
        
        configureDialogsViewController(dialogsController)
        
        dialogsController.onDidFinish = { [unowned self] in
            self.hideExtensionWithCompletionHandler(completion: nil)
        }

    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
//        self.view.transform = CGAffineTransform.init(translationX: 0.0, y: UIScreen.main.bounds.size.height)
//        
//        UIView.animate(withDuration: 0.24) {
//            self.view.transform = CGAffineTransform.identity
//        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !self.dialogsControllerPresented else {
            return
        }
        
        self.dialogsControllerPresented = true
        
        let navController = UINavigationController.init(rootViewController: self.dialogsController!)
        self.present(navController, animated: true, completion: nil)
        
        self.dialogsControllerPresented = true
    }
    
    public func hideExtensionWithCompletionHandler(completion:(()->())?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.transform = CGAffineTransform.init(translationX: 0.0, y: UIScreen.main.bounds.size.height)
        }, completion: { [weak self] _ in
            self?.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
        })
        
    }
    
    open func configureDialogsViewController(_ viewController: DESharedDialogsViewController) {
        // do nothing
    }
    
    public func extensionContextForSharedDialogsViewController(_ viewController: DESharedDialogsViewController) -> NSExtensionContext? {
        return self.extensionContext
    }
}
