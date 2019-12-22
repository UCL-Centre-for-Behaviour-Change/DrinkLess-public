//
//  Config.swift
//  drinkless
//
//  Created by Hari Karam Singh on 04/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

@objc
class AppConfig : NSObject {
    @objc static public var isFirstRun = false
    
    // @TODO merge this with isFirstRun as per logic in AppD
    @objc static public var firstRunDate:Date {
        get {
            let d = UserDefaults.standard.object(forKey: "firstRun") as? Date ?? Date()
            return d
        }
    }
    
    
    /** User server data opt out. Persisted in Userdefs */
    @objc
    static public var userHasOptedOut: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "userHasOptedOut")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "userHasOptedOut")
        }
    }
    
    //---------------------------------------------------------------------

   @objc static public func oneOffEvent(identifier: String, exec:() -> Void) -> Bool {
        let key = "DrinkLess.Event." + identifier
        if !UserDefaults.standard.bool(forKey: key) ||
            (Debug.ENABLED && (Debug.FORCE_ONEOFF_EVENTS.contains(identifier))) {
            
            UserDefaults.standard.set(true, forKey: key)
            exec()
            return true
        }
        return false
    }
}

