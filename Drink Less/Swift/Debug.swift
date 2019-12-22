//
//  Debug.swift
//  drinkless
//
//  Created by Hari Karam Singh on 10/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation

@objc
class Debug : NSObject {
    // Doesnt depend on the ENABLED FLAG! (some of the others might now either!)
    
    @objc static let ENABLED = false
    @objc static let USE_OPENSOURCE_SERVER = false // Independent of ENABLED
    @objc static let LOG_VERBOSE = false
    
    @objc static var SHOW_VC_ON_LAUNCH:[String:String]? = nil //["sb": "Main", "id":""]
    @objc static let FORCE_MIGRATION_VERSION_RANGE:[Int]? = nil //[9500, 9500]
    @objc static let ENABLE_TIME_PANEL = false
    
    // all work independently
    @objc class DataPopulationParams:NSObject {
        @objc public var DO_ERASE = false
        @objc public var DO_DRINKS_RANDOM = false
        @objc public var DO_MOOD_DIARY = false
        @objc public var DO_DRINKS_SPECIFIC = false
        @objc public var DO_AUDIT_HISTORY = false
        @objc public var DO_GOALS = false
        @objc public var DAYS_BACK = 400
        @objc public var MAX_DRINK_QUANTITY = 3
    }
    @objc static let DATA_POPULATION = DataPopulationParams()
//
//    [String:Any] = [
//        "ERASE": false,
//        "DAYS_BACK": 250,
//        "QUANTITY_MAX": 3,
//        "DO_MOOD_DAIRY": false,
//
//        ]
    
    @objc static let ONBOARDING_STEP_THROUGH_TO:String? = nil//"goal" // nil = audit q's, "audit-results", "about-you", "estimate", "feedback", "goal"
    
    /** Force one-off events with given ids to retrigger @see AppConfig */
    @objc static let FORCE_ONEOFF_EVENTS = [String]()
//    @objc static let FORCE_ONEOFF_EVENTS = ["DashboardExplainer"]
    
    /**
     @param Args[0] - Calling VC
     */
    @nonobjc
    class func doHook(_ hook:String, args: NSObject...) {
        guard Debug.ENABLED else { return }
        switch hook {
            
            ////////////////////////////////////////
            // MARK: AppLaunch
            ////////////////////////////////////////
            
            case "AppLaunch" :
                Log.d("Debug ENABLED")
                
//                // Show goals
//                let parentVC = UIApplication.shared.keyWindow!.rootViewController?.childViewControllers.last
//                let goalVC = UIStoryboard(name: "Activities", bundle: nil).instantiateViewController(withIdentifier:"PXEditGoalVC") as! PXEditGoalViewController
//                goalVC.isOnboarding = true
//                parentVC?.present(goalVC, animated: true)
//                
                
                if Debug.DATA_POPULATION.DO_AUDIT_HISTORY {
                    Data.populateAuditHistory()
                }
            
                // Print out some basics for debugging
                Log.d("""
                   
                    
                =================================
                === GLOBALS =====================
                =================================

                DemographicData: \(String(describing: VCInjector.shared.demographicData))
                Lastest AuditData: \(String(describing: AuditData.latest()))
                
                
                First Run Date: \(String(describing: UserDefaults.standard.object(forKey: "firstRun")))
                Current Run Version: \(UserDefaults.standard.integer(forKey: "currentRunVersion"))
                Previous Run Version: \(UserDefaults.standard.integer(forKey: "previousRunVersion"))
                
                Last Migration Version: \(UserDefaults.standard.integer(forKey: "migrations.lastVersion"))
                    
                    
                =================================
                
                    
                """)
            
            ////////////////////////////////////////
            // MARK: DashboardDidAppear
            ////////////////////////////////////////
            
            case "DashboardDidAppear" :
                
                // SHOW VC
                if let vcParams = Debug.SHOW_VC_ON_LAUNCH {
                    let sb = vcParams["sb"]!
                    let id = vcParams["id"]!
                    let dashVC = args[0] as! UIViewController
                    let siblingVC = UIStoryboard(name: sb, bundle: nil).instantiateViewController(withIdentifier:id)
                    dashVC.navigationController?.pushViewController(siblingVC, animated: true)
                }
        
            default :
                Log.w("HOOK '\(hook)' NOT RECOGNISED!")
        }
    }
    
    //---------------------------------------------------------------------

    @objc
    class func doHook(_ hook:String, arg1: NSObject?) {
        if let a = arg1 {
            doHook(hook, args: a)
        } else {
            doHook(hook)
        }
    }
    @objc
    class func doHook(_ hook:String, arg1: NSObject, arg2:NSObject) {
        doHook(hook, args: arg1, arg2)
    }
}


extension Debug {
    struct Data {
        static func populateAuditHistory(erase:Bool = true) {
            Log.d("populateAuditHistory()")
            if erase {
                let context = PXCoreDataManager.shared()!.managedObjectContext!
                let all = AuditDataMO.all(in: context)!
                // Delete all except the onboarding
                for e in all {
                    context.delete(e)
                }
                do {
                    try context.save()
                    Log.d("Erased \(all.count) AuditData records")
                } catch {
                    Log.e("FAILED to erase auditData records")
                }
            }
            
            // Fake entry on various dates
            let MONTHS_BACK = 5 // number in addition to the most recent to go back
            let DAYS_BACK = Int.random(in: 0...30)
            
            var date = NSDate().addingTimeInterval(TimeInterval(-DAYS_BACK*24*3600))
            var c = MONTHS_BACK + 1
            while c >= 0 {
                let o = AuditData()
                o.auditScore = Int.random(in:0...40)
                o.auditCScore = Int.random(in:0...20)
                o.date = date
                o.timezone = TimeZoneProvider.current
                o.demographicKey = "35-44:male"
                o.countryEstimate = 30.0
                o.demographicEstimate = 20.0
                o.calculateActualPercentiles()
                o.setAnswer(questionId: "question9", answerValue:1)
                o.setAnswer(questionId: "question2", answerValue:2)
                o.setAnswer(questionId: "question3", answerValue:3)
                o.setAnswer(questionId: "question10", answerValue:1)
                o.setAnswer(questionId: "question1", answerValue:1)
                o.save(localOnly: true)
                
                c = c - 1
                date = date.addingTimeInterval(TimeInterval(-28*24*3600))
            }
            Log.d("Created \(MONTHS_BACK+1) AuditData records starting from \(DAYS_BACK) days ago")
        }
    }
}
