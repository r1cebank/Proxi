//
//  InterfaceController.swift
//  Proxi WatchKit Extension
//
//  Created by Siyuan Gao on 5/13/15.
//  Copyright (c) 2015 Siyuan Gao. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var tableView: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        loadTableData()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTableDate() {
        tableView.setNumberOfRows(1, withRowType: "")
    }

}
