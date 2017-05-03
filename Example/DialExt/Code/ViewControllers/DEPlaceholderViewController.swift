//
//  DEPlaceholderViewController.swift
//  DialogSDK
//
//  Created by Aleksei Gordeev on 13/01/2017.
//  Copyright © 2017 Dialog LLC. All rights reserved.
//

import Foundation


public protocol DEPlaceholderViewControllerConfigurator {
    func configure(controller: DEPlaceholderViewController)
}

public final class DEPlaceholderViewController: UIViewController {
    
    public class func fromStoryboard() -> DEPlaceholderViewController {
        let bundle = Bundle.dialExtResourcesBundle
        let storyboard = UIStoryboard.loadFirstFound(name: "DEPlaceholderViewController", bundles: [bundle])!
        let controller = storyboard.instantiateInitialViewController() as! DEPlaceholderViewController
        return controller
    }
    
    public final class BasicConfigurator: DEPlaceholderViewControllerConfigurator {
        
        var preconfig: Preconfig
        
        public init(preconfig: Preconfig) {
            self.preconfig = preconfig
        }
        
        public func configure(controller: DEPlaceholderViewController) {
            
            UIView.performWithoutAnimation {
                
                switch preconfig {
                    
                case .noDialogs():
                    controller.titleLabelViewHideable.isHidden = false
                    controller.titleLabel.text = "TEST"
                    
                    controller.actionButtonViewHideable.isHidden = true
                    
                    controller.subtitleLabelViewHideable.isHidden = true
                    controller.imageViewHideable.isHidden = true
                }
            }
        }
        
        public enum Preconfig {
            case noDialogs()
        }
    }
    
    @IBOutlet public private(set) var imageViewHideable: UIView!
    @IBOutlet public private(set) var imageView: UIImageView!
    
    @IBOutlet public private(set) var titleLabelViewHideable: UIView!
    @IBOutlet public private(set) var titleLabel: UILabel!
    
    @IBOutlet public private(set) var subtitleLabelViewHideable: UIView!
    @IBOutlet public private(set) var subtitleLabel: UILabel!
    
    @IBOutlet public private(set) var actionButtonViewHideable: UIView!
    @IBOutlet public private(set) var actionButton: UIButton!
    
    /// Stores value untill view is loaded and clear it. After loading ignore this value.
    private var configuratorToApplyOnViewDidLoad: DEPlaceholderViewControllerConfigurator?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        if let configurator = configuratorToApplyOnViewDidLoad {
            configure(configurator)
        }
    }
    
    public func configure(_ configurator: DEPlaceholderViewControllerConfigurator) {
        if self.isViewLoaded {
            configurator.configure(controller: self)
        }
        else {
            configuratorToApplyOnViewDidLoad = configurator
        }
    }
}
