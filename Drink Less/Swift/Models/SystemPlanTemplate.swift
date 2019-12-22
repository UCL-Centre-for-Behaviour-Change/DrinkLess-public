//
//  SystemPlanTemplate.swift
//  drinkless
//
//  Created by Hari Karam Singh on 04/03/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import UIKit

class SystemPlanTemplate: NSObject, PlanTemplate {

    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    public var identifier: Int16 = -1
    public var label: String = ""
    public var icon: String = ""
    
    //---------------------------------------------------------------------

    private static let dataStore:[[String:AnyObject]] = { () -> [[String:AnyObject]] in
        let path = Bundle.main.path(forResource: "MakePlanData", ofType: "plist")!
        let plist = NSDictionary(contentsOfFile: path)! as! [String:Array<AnyObject>]
        return plist["systemTemplates"] as! [[String:AnyObject]]
    }()
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    class func loadAll() -> [SystemPlanTemplate] {
        var allEntries = [SystemPlanTemplate]()
        for entry in SystemPlanTemplate.dataStore {
            allEntries.append(SystemPlanTemplate(id: entry["identifier"] as! Int16)!)
        }
        return allEntries
    }
    
    //---------------------------------------------------------------------

    required init?(id: Int16) {
        var found = false
        for entry in SystemPlanTemplate.dataStore {
            if (entry["identifier"] as! Int) == id {
                label = (entry["label"] as! String?)!
                icon = (entry["icon"] as! String?)!
                identifier = id
                found = true
                break
            }
        }
        if !found {
            return nil
        }
        super.init()
    }
}
