//
//  Migrations.swift
//  drinkless
//
//  Created by Hari Karam Singh on 15/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation
import UIKit

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

//internal typealias MigrationCallback = ([MigrationError]?) -> Void

protocol Migration {
    static func execute() -> [MigrationError]?
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

/**
 Handles data migrations. Important see notes
 */
@objc 
class MigrationManager: NSObject {
    
    //    private static let CURR_RUN_VERSION_KEY = "currentRunVersion"  // See AppD
    //    private static let PREV_RUN_VERSION_KEY = "previousRunVersion"  // See AppD
    private static let FIRST_RUN_DATE_KEY = "firstRun"  // See AppD (rtn NSDate)
    private static let LAST_MIGRATION_VERSION_KEY = "migrations.lastVersion"  // last version migrated
//    private static let LAST_MIGRATION_ERRORS_KEY = "migrations.lastErrors"
    
    class var defs : UserDefaults {
        return UserDefaults.standard
    }
    
//    private static let queue: DispatchQueue = DispatchQueue(label: "com.ucl.drinkless.migrations", attributes: .concurrent)
    
    
    //////////////////////////////////////////////////////////
    // MARK: - MIGRATION LOOKUP TABLE
    //////////////////////////////////////////////////////////
    
    static var MigrationClassLookup:[Int: Migration.Type] = [
        9400: Migration_9400.self,
        9500: Migration_9500.self,
    ]
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Public Methods
    //////////////////////////////////////////////////////////
    
    /** ALWAYS call this. Even on first run. */
    @objc class func doMigrations(/*_ callback:@escaping MigrationCallback*/) -> [MigrationError]? {
        Log.i("Checking for migrations...")
        
        if isFreshInstall() {
            Log.i("Fresh install. No migrations required.")
            defs.set(roundTo100(UIApplication.versionInt()), forKey: LAST_MIGRATION_VERSION_KEY)
            return nil
        }
        
        var versionStart:Int
        var versionEnd:Int
        if Debug.ENABLED, let debugRange = Debug.FORCE_MIGRATION_VERSION_RANGE {
            (versionStart, versionEnd) = (debugRange[0], debugRange[1])
        } else {
            (versionStart, versionEnd) = getVersionRange()
        }
        
        Log.d("Checking for migrations between \(versionStart) and \(versionEnd)...")
        
        var allErrors = [MigrationError]()
//        let waitGroup = DispatchGroup()
//        var hadAtLeastOne = false
        for ver in stride(from:versionStart, to:versionEnd + 1, by:100) {
            if let cls = MigrationClassLookup[ver] {
                Log.i("Migration found for version \(ver)...")
                
//                hadAtLeastOne = true
//                waitGroup.enter()
//                queue.async(group: waitGroup) {
                if let errors = cls.execute() {
                    allErrors.append(contentsOf: errors)
                    
                    DataServer.shared.logError("Migrations", msg: "Failed migrating version \(ver)", info: ["errors": errors])
                    Log.e("Failed migrating version \(ver). Errors: \(errors)")
                    
                } else {
                    defs.set(ver, forKey: LAST_MIGRATION_VERSION_KEY)
                    Log.i("Completed migration for version \(ver).")
                }
                
//                        waitGroup.leave()
//                    } // end .execute()
//                } // end .async
            }
        }
        
//        if !hadAtLeastOne {
//            callback(nil)
//            return
//        }
        // Otherwise wait for the group to finish
//        waitGroup.notify(queue: .main) {
            Log.i("Migrations check finished")
            Log.d("Errors: \(allErrors)")
            let rtn = allErrors.count > 0 ? allErrors : nil
            return rtn
//        }
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////
    
    private class func isFreshInstall() -> Bool {
        return defs.object(forKey: FIRST_RUN_DATE_KEY) == nil
    }
    
    private class func getVersionRange() -> (Int, Int) {
        let start = roundTo100(defs.integer(forKey: LAST_MIGRATION_VERSION_KEY)) + 100
        let end = roundTo100(UIApplication.versionInt())
        assert(end > 0)
        
        return (start, end)
    }
    
    private class func roundTo100(_ x:Int) -> Int {
        return Int(x/100 * 100)
    }
}


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


@objc
class MigrationError: NSObject {
    @objc var isFatal:Bool
    @objc var message:String
    @objc var underlyingError:NSError?
    
    override var debugDescription: String{
        return "<MigrationError: message=\"\(message)\" isFatal=\(isFatal ? "true":"false") underlyingError=\(String(describing:underlyingError)) >"
    }
    
    init(_ msg:String, fatal:Bool = true, underlying:NSError? = nil) {
        message = msg
        isFatal = fatal
        underlyingError = underlying
    }
    
    @objc func toNSError() -> NSError {
        var userInfo:[String: Any] = [ NSLocalizedDescriptionKey: message ]
        if let e2 = underlyingError {
            userInfo[NSUnderlyingErrorKey] = e2
        }
        return NSError(domain: "MigrationDomain", code: 500, userInfo: userInfo)
    }
    
    
}

