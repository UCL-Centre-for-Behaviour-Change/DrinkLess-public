//
//  Analytics.swift
//  drinkless
//
//  Created by Hari Karam Singh on 04/08/2020.
//  Copyright © 2020 UCL. All rights reserved.
//

import UIKit
import Firebase

class Analytics: NSObject {
    
    @objc
    public static let shared = Analytics()
    
    @objc
    public var userOptedOut = true { // for now so we can catch that crash bug AppConfig.userHasOptedOut {
        didSet {
            FirebaseApp.app()!.isDataCollectionDefaultEnabled = !userOptedOut  // takes effect next run
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(!userOptedOut) // instant override i think ??
            Performance.sharedInstance().isDataCollectionEnabled = !userOptedOut  // ditto ??
            Log.d("Analytics Opt Out? \(userOptedOut ? "YES" : "NO")")
        }
    }
    
    private override init() {}
    
    
    @objc
    public func setup() {
        FirebaseApp.configure()
        let val = userOptedOut  // Trigger initialisers
        userOptedOut = val
    }
    
    @objc
    public func logCrashMessage(_ msg: String) {
        guard !userOptedOut else { return }
        setCrashUser()
        
        Crashlytics.crashlytics().log(msg)
        Log.d("Logging crash message: \(msg)")
    }
    
    @objc
    public func logCrashInfo(_ info: [String:Any]) {
        guard !userOptedOut else { return }
        setCrashUser()
        
        for (key, val) in info {
            Crashlytics.crashlytics().setCustomValue(val, forKey: key)
        }
        
        Log.d("Logging crash info: \(info)")
    }
    
    @objc
    public func crashMe() {
        guard Debug.ENABLED else { return }
        fatalError()
    }
        
    
    private func setCrashUser() {
        guard !userOptedOut else { return }
        if let userId = PFUser.current()?.objectId {
            Crashlytics.crashlytics().setUserID(userId)
            Log.d("Logging crash user: \(String(describing:PFUser.current()?.objectId))")
        } else {
            Log.d("WARNING: User not set yet.")
        }
    }
    
    
    
}
