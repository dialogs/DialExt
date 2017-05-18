//
//  DEDialogCellTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 19/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest

@testable import DialExt

class DEDialogCellTests: XCTestCase {
    
    var cell: DEDialogCell!
    
    override func setUp() {
        super.setUp()
        
        let config = DESharedDataConfig(keychainGroup: "", appGroup: "", uploadURLs: [])
        let controller = DESharedDialogsViewController.createFromDefaultStoryboard(config: config)
        controller.debug_stopsAtViewDidLoad = true
        controller.loadViewIfNeeded()
        let cell = controller.tableView.dequeueReusableCell(withIdentifier: "DEDialogCell")
        self.cell = cell as! DEDialogCell
    }

    func testCellInitiallyConfiguredOnce() {
        
        // MARK: Given
        
        var configureCounter = 0
        
        let name = "1"
        let status = "2"
        
        
        
        // MARK: When
        
        for _ in 0..<10 {
            cell.initiallyConfigure {
                configureCounter += 1
                
                cell.nameLabel.text = name
                cell.statusLabel.text = status
            }
        }
        
        
        // MARK: Then
        
        XCTAssert(configureCounter == 1, "Cell was not confgiured one time only")
        
        XCTAssertEqual(cell.nameLabel.text, name, "Name isn't configured")
        XCTAssertEqual(cell.statusLabel.text, status, "Status isn't configured")
    }
    
}
