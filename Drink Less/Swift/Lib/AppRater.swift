//
//  AppRater.swift
//  drinkless
//
//  Created by Hari Karam on 15/04/2021.
//  Copyright © 2021 UCL. All rights reserved.
//

import Foundation
import StoreKit

@objc
public class AppRater : NSObject {
    struct Const {
        static let DAYS_UNTIL_PROMPT = 7
        static let RUNS_UNTIL_PROMPT = 11
        static let FIRST_RUN_DATE_KEY = "AppRater::FIRST_RUN_DATE_KEY"
        static let NUM_RUNS_DATE_KEY = "AppRater::NUM_RUNS_DATE_KEY"
        static let HAS_SHOWN_KEY = "AppRater::HAS_SHOWN_KEY"
    }
    
    // Set when markRun is called
    private var shouldRate = false

    // Singletonise
    @objc public static let shared = AppRater()
    private override init() {
        // debug reset
        //UserDefaults.standard.set(false, forKey: Const.HAS_SHOWN_KEY)
    }
    
    
    @objc
    func markRun() {
        let defs = UserDefaults.standard
        
        // FIRST RUN
        // Initialise if first run. Then do comparison
        var firstRunDate:Date? = defs.object(forKey: Const.FIRST_RUN_DATE_KEY) as? Date
        if firstRunDate == nil {
            firstRunDate = Date()
            defs.set(firstRunDate, forKey: Const.FIRST_RUN_DATE_KEY)
        }
        
        let daysSinceFirstRun = Date().timeIntervalSince(firstRunDate!) / (3600.0*24.0)
        shouldRate = shouldRate || (daysSinceFirstRun > Double(Const.DAYS_UNTIL_PROMPT))
        
        // RUNS COUNT
        var runCount:Int = defs.integer(forKey: Const.NUM_RUNS_DATE_KEY) // 0 if none set
        runCount += 1;
        defs.set(runCount, forKey: Const.NUM_RUNS_DATE_KEY)
        
        shouldRate = shouldRate || (runCount >= Const.RUNS_UNTIL_PROMPT)
        
        Log.d("[AppRater] Days since first run: \(daysSinceFirstRun)  Run Count: \(runCount)  shouldRate: \(shouldRate ? "YES" : "NO")")
    }
    
    
    // Show if ready
    @objc
    func showRaterIfReady() {
        let defs = UserDefaults.standard
        let hasShownAlready = defs.bool(forKey: Const.HAS_SHOWN_KEY)
        
        if hasShownAlready {
            Log.d("[AppRater] Skipping as already shown to user")
            return
        }
        
        if shouldRate {
            showRater()
        } else {
            Log.d("[AppRater] Not showing rating (as not yet ready)")
        }
    }
    
    // Force show
    @objc
    func showRater() {
        Log.d("[AppRater] Showing rating and marking as shown")
        SKStoreReviewController.requestReview()
        UserDefaults.standard.set(true, forKey: Const.HAS_SHOWN_KEY)
    }
    
    
}

