//
//  GroupData.swift
//  drinkless
//
//  Created by Hari Karam Singh on 01/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

@objc
public class GroupData: NSObject {
    @objc enum PopulationType: Int {
        case country
        case demographic
    }
    @objc enum GroupType: Int {
        case everyone
        case drinkers
    }
    @objc public enum GenderType: Int {
        case male
        case female
        case none
    }

    //---------------------------------------------------------------------

    var groupDataAll: Array<Dictionary<String, NSNumber>>
    var groupDataDrinkers: Array<Dictionary<String, NSNumber>>

    //---------------------------------------------------------------------

    required public override init() {
        let path = Bundle.main.path(forResource: "AuditGroupAll_sept18", ofType: "plist")!
        groupDataAll = NSArray(contentsOfFile: path) as! Array<Dictionary<String, NSNumber>>
        
        let path2 = Bundle.main.path(forResource: "AuditGroupDrinkers_sept18", ofType: "plist")!
        groupDataDrinkers = NSArray(contentsOfFile: path2) as! Array<Dictionary<String, NSNumber>>
    }
    
    
    
}
