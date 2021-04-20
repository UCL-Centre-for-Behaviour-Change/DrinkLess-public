//
//  MRTNotificationsManager.swift
//  drinkless
//
//  Created by Hari Karam Singh on 05/09/2019.
//  Copyright © 2019 UCL. All rights reserved.
//

import UIKit
import UserNotifications

@objc
class MRTNotificationsManager: NSObject {
    
    /////////////////////////////////////////
    // MARK: - Debug
    /////////////////////////////////////////
    // These require Debug.ENABLED
    private let DBG_FORCE_SKIP_MRT:Bool = false     // Skip the MRT checks and notif scheduling in the beginning
    private let DBG_FORCE_VERSION:String? = nil //"C" //"A"   // set to nil to disable
    private let DBG_FORCE_C_SUBVERSION:String? = nil //"c3" //"c3"   // set to nil to disable
    private let DBG_CLEAR_EXISTING_NOTIFS_ON_LAUNCH = false
    private let DBG_OVERRIDE_SCHEDULING = false
    private let DBG_OVERRIDE_SCHEDULING_TIME_INTERVAL = 30.seconds  // first one will be scheduled for this time from now
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Settings
    //////////////////////////////////////////////////////////

//    private let MAX_SCHEDULED_NOTIFS = 10
    private let MAX_SCHEDULED_NOTIFS = 64 - 32  // ...64 is the max but back off a few to leave room for other notifs (eg My Plans).

    // Notifs continue to run nd be reported after new participants cutoff date
//    private let TRIAL_REGISTRATION_CUTOFF_DATECOMPS = DateComponents(year: 2019, month: 12, day: 13)
//    private let TRIAL_NOTIFICATIONS_CUTOFF_DATECOMPS = DateComponents(year: 2019, month: 12, day: 15)
    private let TRIAL_REGISTRATION_CUTOFF_DATECOMPS = DateComponents(year: 2020, month: 4, day: 1)
    private let TRIAL_NOTIFICATIONS_CUTOFF_DATECOMPS = DateComponents(year: 2020, month: 5, day: 1)
    
    private let MIN_AUDIT_SCORE = 8
    
    // Randomisation weightings
    private let VERSION_PROBS = ["A": 1, "B": 1, "C": 3]
    private let VERSION_C_PROBS = ["c1": 4, "c2": 3, "c3": 3]
    
    private let NOTIF_SCHEDULE_HOUR_LOOKUP = ["B": 11, "C": 20] //11am, 8pm
    private let NOTIF_TITLE_REMINDER = "Reminder"
    private let NOTIF_TITLE_TIP = "Quick tip…"
    private let DEFAULT_MESSAGE = "Please complete your mood and drinks diary"
    private let DEFAULT_ACTION_ID = "add-todays-drinks"
    
    
    
   
    //////////////////////////////////////////////////////////
    // MARK: - Publics
    //////////////////////////////////////////////////////////

    @objc public var appIsInForeground = false
    
    //---------------------------------------------------------------------

    /** Answers to the MRT terms at onboarding. See form input names in @see mrt-terms.html for keys */
    public var mrtTermsAnswers = [String:Bool]()
    
    //////////////////////////////////////////////////////////
    // MARK: - Read Only
    //////////////////////////////////////////////////////////

    // ...in current calendar
    @objc
    public var notificationsCutoffDate:Date {
        return CalendarProvider.current.date(from: self.TRIAL_NOTIFICATIONS_CUTOFF_DATECOMPS)!
    }
    
    //---------------------------------------------------------------------
    
    @objc
    public var registrationCutoffDate:Date {
        return CalendarProvider.current.date(from: self.TRIAL_REGISTRATION_CUTOFF_DATECOMPS)!
    }
    
    //---------------------------------------------------------------------
    
    @objc
    public var isWithinTrialRegistrationDates:Bool {
        let now = DateProvider.now
        return now < registrationCutoffDate
    }
    
    //---------------------------------------------------------------------

    @objc
    public var isWithinTrialNotificationCutoffDate:Bool {
        let now = DateProvider.now
        return now < notificationsCutoffDate
    }
    
    
    //---------------------------------------------------------------------

    @objc
    public var userIsTrialParticipant:Bool {
        return trialVersion != nil
    }
    
    //---------------------------------------------------------------------

    @objc var trialIsActivelyRunning:Bool {
        return userIsTrialParticipant && isWithinTrialNotificationCutoffDate 
    }
    
    //---------------------------------------------------------------------

    /**
     Handler and compatibility manager for local notifs currently employed by the app
     
     @return True if it was an MRT notif, false otherwise
     */
    @objc public func handleMRTNotification(_ notification:UNNotification) -> Bool {
        // Detect MRT notif. Ensure we have the right details
        let userInfo = notification.request.content.userInfo
        guard let notifType = userInfo[KEY_LOCALNOTIFICATION_TYPE] as? String,
            let notifId = userInfo[KEY_LOCALNOTIFICATION_ID] as? String,
            notifType == MRTNotificationType  else {
            return false
        }
       
        // Check they haven't opted out in the meantime
        if AppConfig.userHasOptedOut {
            Log.i("MRT -- User has since opted out. Won't report")
            return true
        }
        
        // Update the tracking and changed the status to reflect action
        let queryParams = ["notificationId": notifId]
        let status = self.appIsInForeground ? "already-open" : "user-tapped"
        let timezoneStr = CalendarProvider.current.timeZone.identifier
        let updateParams = ["status": status, "mostRecentTimezone": timezoneStr]
        
        DataServer.shared.updateDataObjects(self.NotificationsTrackingClassName, queryParams: queryParams, updateParams: updateParams) { (success:Bool , objectId:String?, error:Error?) in
            if let err = error {
                Log.e("MRT -- Error updating notification record in Parse: \(err)")
                return
            }
            Log.i("MRT -- Updated record in Parse for notification id=\(notifId) status=\(status)")
        }
        
        return true
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Private Props
    //////////////////////////////////////////////////////////

    struct Keys {
        static let userFirstRunWasDuringMRTKey = "MRT.userFirstWasRunDuringMRT"
        static let whichVersionKey = "MRT.whichTrial"
        static let lastScheduledDateCompsKey = "MRT.lastScheduledDateComps"
        static let hasBeenRegisteredKey = "MRT.hasBeenRegistered"
        static let hasResetAfterTrialEndKey = "MRT.hasResetAfterTrialEnd"
    }

    //---------------------------------------------------------------------

    // Parse table names
    private let ParticipantsTrackingClassName = "MRTParticipants"
    private let NotificationsTrackingClassName = "MRTNotifications"
    
    //---------------------------------------------------------------------

    private let MRTNotificationType = "MRTNotificationType"
    
    //---------------------------------------------------------------------
    
    private let userDefs = UserDefaults.standard
    private var onboardingCompleteNotifRef:NSObjectProtocol?       // for storing the reference the onboarding complete notif
    
    
    //---------------------------------------------------------------------

    /** Note! This is different than isUserTrialParticipant. This one just means they've been through the process (and possible deemed inelgible). See `userIsTrialParticipant` */
    private var hasBeenThroughEligibilityCheck:Bool {
        get {
            return userDefs.bool(forKey: Keys.hasBeenRegisteredKey)
        }
        set {
            userDefs.set(newValue, forKey: Keys.hasBeenRegisteredKey)
        }
    }
    
    //---------------------------------------------------------------------

    /** Nil means not qualified for trial (or havent registered yet) */
    private var trialVersion:String? {
        if Debug.ENABLED, let forceVer = self.DBG_FORCE_VERSION {
            return forceVer
        }
            
        return userDefs.object(forKey: Keys.whichVersionKey) as? String
    }
   
    //---------------------------------------------------------------------
    
    /** Used to append to the queue of notifs scheduled on previous runs */
    private var lastScheduledNotifDateComps:DateComponents? {
        get {
            guard let data = userDefs.data(forKey: Keys.lastScheduledDateCompsKey) else {
                return nil
            }
            let dateComps = try? JSONDecoder().decode(DateComponents.self, from: data)
            return dateComps
        }
        set {
            if let val = newValue {
                let data = try! JSONEncoder().encode(val)
                userDefs.set(data, forKey: Keys.lastScheduledDateCompsKey)
            } else {
                userDefs.set(nil, forKey: Keys.lastScheduledDateCompsKey)
            }
        }
    }
    
    //---------------------------------------------------------------------

    /** The messages and actionIds */
    lazy private var notifDetailsListForC3 : [[String:String]] = {
        let path = Bundle.main.path(forResource: "mrt-data", ofType: "plist")!
        let data = NSDictionary(contentsOfFile: path)!
        let entries = data["Messages"] as! [[String:String]]
        return entries
    }()
    
    //---------------------------------------------------------------------

    // For debugging randomiser
    private var cTally:[String:Int] = ["c1":0, "c2":0, "c3":0]
    private var rTally = [Int:Int]()
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    @objc 
    public static let shared = MRTNotificationsManager()

    //---------------------------------------------------------------------

    override init() {
        super.init()
    }
    
    @objc
    public func launch(isFirstRun:Bool) {
        if (Debug.ENABLED && DBG_FORCE_SKIP_MRT) {
            Log.d("MRT -- Skipping MRT (debug flag))")
            return
        }
        
        /////////////////////////////////////////
        // OPT OUT
        /////////////////////////////////////////
        // Note this wont catch first run opt outs as its called before the first terms screen is answered
        if AppConfig.userHasOptedOut {
            Log.i("MRT -- Setup -- User opted out of data sharing.")
            return
        }
        
        /////////////////////////////////////////
        // IS NEW USER CHECK (Ie. Don't register users who upgraded into MRT.)
        /////////////////////////////////////////
        // Note this must be before the reset action below or else upgraded users will have their PXConsumptionReminderType setting overwritten
        
        // Check for key existence and set it to the passed in value for (app) First Run
        if userDefs.object(forKey: Keys.userFirstRunWasDuringMRTKey) == nil {
            Log.i("MRT first run. App first run? \(isFirstRun ? "Yes":"No")");
            // Assign to the passed in value
            userDefs.set(isFirstRun, forKey: Keys.userFirstRunWasDuringMRTKey)
        }
        // If not then this is a user who upgraded into MRT. Skip them.
        if !userDefs.bool(forKey: Keys.userFirstRunWasDuringMRTKey) {
            Log.i("MRT -- User upgraded into MRT. Skipping them.")
            return;
        } else {
            Log.i("MRT -- Good User (App first run was after MRT started.)")
        }
        
        
        /////////////////////////////////////////
        // TRIAL ENDED? RESET OLD NOTIFS
        /////////////////////////////////////////
        if userIsTrialParticipant && !isWithinTrialNotificationCutoffDate {
            Log.i("MRT -- Setup -- Trial ended. Doing nothing.")
            
            let hasReset = userDefs.bool(forKey: Keys.hasResetAfterTrialEndKey)
            if !hasReset {
                
                Log.i("MRT -- Re-enabling Reminder notif after trial end")
                self.userDefs.set(true, forKey:"PXConsumptionReminderType")
                self.userDefs.synchronize() // just in case the swift/objc handling isnt clean
                PXLocalNotificationsManager.sharedInstance().updateConsumptionReminder()
                
                userDefs.set(true, forKey: Keys.hasResetAfterTrialEndKey)
            }
            return
        }
        if (!isWithinTrialNotificationCutoffDate) {
            Log.i("MRT -- Setup -- Quiting as Notif Cutoff Date is passed")
            return
        }
        
        /////////////////////////////////////////
        // REGISTER USER HOOK (w/ notif update too)
        /////////////////////////////////////////
        
        guard hasBeenThroughEligibilityCheck else {
            
            // Confirm registration date hasn't been exceeded
            if !isWithinTrialRegistrationDates {
                Log.i("MRT -- Registration cutoff has been passed. Not registering")
                return
            }
            
            Log.i("MRT -- Setup -- Not registered yet. Listening for onboarding to finish...")
            // Prevent multiple execution if user suspends/resumes
            if let notifRef = onboardingCompleteNotifRef {
                NotificationCenter.default.removeObserver(notifRef)
            }
            onboardingCompleteNotifRef = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "PXFinishIntro"), object: nil, queue: nil) { (n:Notification) in
                
                Log.i("MRT -- Setup -- Onboarding finished. Registering user...")
                
                // All checks done inside the register method
                self.registerUser() { (didQualify:Bool) in
                    self.hasBeenThroughEligibilityCheck = true
                    
                    if didQualify {
                        
                        // Disable the existing reminder
                        Log.i("MRT -- Disabling existing Reminder notif")
                        self.userDefs.set(false, forKey:"PXConsumptionReminderType")
                        self.userDefs.synchronize() // just in case the swift/objc handling isnt clean
                        PXLocalNotificationsManager.sharedInstance().updateConsumptionReminder()
                        
                        // Schedule our notifs
                        self.updateScheduledNotifications()
                    }
                }
                NotificationCenter.default.removeObserver(self.onboardingCompleteNotifRef!)
            }
            return
        }
        
        /////////////////////////////////////////
        // REQUEST NOTIF
        /////////////////////////////////////////
        
        Log.i("MRT - Previously registered. Checking notif auth")
        checkNotifAuth() { (hasNotifAuth:Bool) in
            if hasNotifAuth {
                Log.i("MRT -- Has notif auth. Updating schedule")
                
                if Debug.ENABLED && self.DBG_CLEAR_EXISTING_NOTIFS_ON_LAUNCH {
                    Log.d("MRT -- Erasing existing notifs")
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    self.lastScheduledNotifDateComps = nil
                }
                
                // Needed?? YES of course, for app runs after user has registered
                self.updateScheduledNotifications()
            } else {
                Log.i("MRT -- User has denied notifications.")
            }
        }
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    private func checkNotifAuth(callback:@escaping (_ userHasAuthorizedNotifs:Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings() {
            (settings:UNNotificationSettings) -> Void in
            
            let auth = settings.authorizationStatus
            callback(auth != .notDetermined && auth != .denied)
        }
    }
    
    //---------------------------------------------------------------------
    private func updateScheduledNotifications() {
        Log.i("MRT -- Updating scheduled notifications (trial=\(trialVersion ?? ""))...")
        
        if !userIsTrialParticipant {
            Log.i("MRT -- Skipping as user is not qualified for trial (or reg hasn't happened yet)")
            return
        }
        
        // Also Version A is nothing
        if trialVersion == "A" {
            Log.i("MRT -- Skipping as per spec for Version A")
            return
        }
        
        // Iterate to fill up the schedule queue
        //UNUserNotificationCenter.current().removeAllDeliveredNotifications() // this removes the delivered ones from the notification center in the lock/overlay screen. dont want that really
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notifs:[UNNotificationRequest]) in
            
            let numToAdd = self.MAX_SCHEDULED_NOTIFS - notifs.count
            if numToAdd < 1 {
                Log.d("MRT -- No space for additional notifs. Cnt=\(notifs.count).")
                return
            }
            
            var lastScheduleDateComps:DateComponents?
            
            // Grab from out last schedule. If the current date has surpassed this or we haven't set it yet, start from tomorrow
            let nowDateComps = CalendarProvider.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: DateProvider.now)
            if self.lastScheduledNotifDateComps != nil {
                let lastSchedDate = CalendarProvider.current.date(from: self.lastScheduledNotifDateComps!)!
                if DateProvider.now < lastSchedDate {
                    lastScheduleDateComps = self.lastScheduledNotifDateComps!
                } else {
                    Log.i("MRT -- LastScheduledDate is in the past. Starting notif scheduling loop from Now")
                }
            }
            if lastScheduleDateComps == nil {
                lastScheduleDateComps = nowDateComps
            }
            
            Log.v("MRT -- Adding \(numToAdd) notifications from date \(lastScheduleDateComps!)")

            // Our start date
            var scheduleDate = CalendarProvider.current.date(from: lastScheduleDateComps!)!
            if Debug.ENABLED && self.DBG_OVERRIDE_SCHEDULING {
                scheduleDate += 1.minutes - self.DBG_OVERRIDE_SCHEDULING_TIME_INTERVAL
            }
            var toScheduleDateComps = DateComponents()
            for _ in 1...numToAdd {
                
                // Add one day to the date comps. use the current calendar and convert back to calendar (and tz) agnostic DateComps
                if !(self.DBG_OVERRIDE_SCHEDULING && Debug.ENABLED) {
                    scheduleDate = scheduleDate + 1.days
                    toScheduleDateComps = CalendarProvider.current.dateComponents([.year, .month, .day], from: scheduleDate)
                    // Set the hour
                    toScheduleDateComps.hour = self.NOTIF_SCHEDULE_HOUR_LOOKUP[self.trialVersion!]!
                    toScheduleDateComps.minute = 0
                    toScheduleDateComps.second = 0
                } else {
                    let interval = self.DBG_OVERRIDE_SCHEDULING_TIME_INTERVAL
                    scheduleDate = scheduleDate + interval
                    toScheduleDateComps = CalendarProvider.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduleDate)
                }
                
                // Abort if this runs past the trial end. (Note, doesnt matter that scheduleDate has h:m:s as trialEndDate is based on 00:00:00
                if scheduleDate >= self.notificationsCutoffDate {
                    Log.v("MRT -- Stopping as we've exceeded our trial end date (notification cutoff date)")
                    break
                }
                
                 // Get the message and the action from the appropriate generator
                var title:String?
                var message:String?
                var actionId:String?
                var notificationId:String?
                var subversion:String?
            
                self.getNotificationDetails(version: self.trialVersion!, notifDateComps: toScheduleDateComps, title:&title, message: &message, actionId: &actionId, subversion:&subversion, notifId: &notificationId)
                
                if let msg = message, let notifId = notificationId {
                    // SCHEDULE IT
                    
                    let dateStr = String(format: "%04d-%02d-%02d %02d:%02d:%02d", toScheduleDateComps.year!, toScheduleDateComps.month!, toScheduleDateComps.day!, toScheduleDateComps.hour!, toScheduleDateComps.minute!, toScheduleDateComps.second!)
                    
                    let userInfo:[String:Any] = [KEY_LOCALNOTIFICATION_ID: notifId, KEY_LOCALNOTIFICATION_TYPE: self.MRTNotificationType]
                    UNUserNotificationCenter.current().scheduleLocalNotification(identifier: notifId, title: title, body:message, userInfo:userInfo, dateComps: toScheduleDateComps) { (error:Error?) -> Void in
                    
                        let timezoneStr = CalendarProvider.current.timeZone.identifier
                        var trackingParams = ["status":"scheduled", "notificationId":notifId, "version": self.trialVersion!, "subversion":subversion ?? "", "message": message ?? "", "localScheduledDate": dateStr, "mostRecentTimezone": timezoneStr]
                        if let e = error {
                            Log.e("Error scheduling: \(e)")
                            trackingParams["status"] = "error"
                            return
                        }
                        Log.v("MRT -- Scheduled message id=\(notifId) msg='\(msg)' actionId='\(actionId ?? "")'")
                        
                        DataServer.shared.saveDataObject(className: self.NotificationsTrackingClassName, objectId: nil, isUser: true, params: trackingParams, ensureSave: true, callback: nil)
                    }
                    
                } else {
                    // Track C1 (no notification)
                    let dateStr = String(format: "%04d-%02d-%02d %02d:%02d:%02d", toScheduleDateComps.year!, toScheduleDateComps.month!, toScheduleDateComps.day!, toScheduleDateComps.hour!, toScheduleDateComps.minute!, toScheduleDateComps.second!)
                    let timezoneStr = CalendarProvider.current.timeZone.identifier
                    let trackingParams = ["status":"no notification", "notificationId":"", "version": self.trialVersion!, "subversion":subversion ?? "", "message": "", "localScheduledDate": dateStr, "mostRecentTimezone": timezoneStr]
                    DataServer.shared.saveDataObject(className: self.NotificationsTrackingClassName, objectId: nil, isUser: true, params: trackingParams, ensureSave: true, callback: nil)
                }
            } // end for
            
            // Update the last scheduled (user defs)
            self.lastScheduledNotifDateComps = toScheduleDateComps
        
            Log.d("MRT -- cTally: \(self.cTally)")
            Log.d("MRT -- rTally: \(self.rTally)")
        }
        
    }
    
   
    //---------------------------------------------------------------------
    
    private func getNotificationDetails(version:String, notifDateComps:DateComponents, title: inout String?, message:inout String?, actionId:inout String?, subversion:inout String?, notifId:inout String?) {
        
        subversion = nil
        
        let idSuffix = "\(notifDateComps.year ?? 0)-\(notifDateComps.month ?? 0)-\(notifDateComps.day ?? 0)-\(notifDateComps.hour ?? 0):\(notifDateComps.minute ?? 0):\(notifDateComps.second ?? 0)"
        if version == "B" {
            title = NOTIF_TITLE_REMINDER
            message = DEFAULT_MESSAGE
            actionId = DEFAULT_MESSAGE
            notifId = "B-\(idSuffix)"
            return
        }
        guard version == "C" else {
            // Version A does nothing and should have been caught before now
            Log.w("MRT -- Trial version should be C! =\(String(describing: self.trialVersion))")
            message = nil
            actionId = nil
            notifId = nil
            return
        }
        
        // Get the C subversion
        if Debug.ENABLED, let subv = DBG_FORCE_C_SUBVERSION {
            subversion = subv
        } else {
            subversion = chooseRandom(weights: VERSION_C_PROBS)
        }
        self.cTally[subversion!] = cTally[subversion!]! + 1
        
        if subversion == "c1" {
            Log.d("MRT -- Subversion 'c1': No message")
            title = nil
            message = nil
            actionId = nil
            notifId = nil
            return
        }
        if subversion == "c2" {
            title = NOTIF_TITLE_REMINDER
            message = DEFAULT_MESSAGE
            actionId = DEFAULT_ACTION_ID
            notifId = "C2-\(idSuffix)"
            Log.d("MRT -- Subversion 'c2': Default message")
            return
        }
        if subversion == "c3" {
            let randomIdx = Int.random(in: 0..<notifDetailsListForC3.count)
            title = NOTIF_TITLE_TIP
            message = notifDetailsListForC3[randomIdx]["message"]
            actionId = notifDetailsListForC3[randomIdx]["actionId"]
            notifId = "C3-\(randomIdx)-\(idSuffix)"
            Log.d("MRT -- Subversion 'c3': Choosing from list \"\(message ?? "")\"")
        
            return
        }
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////
    
    /** Only call at the end of the onboarding. Logs the user even if they aren't interested */
    private func registerUser(callback:@escaping (Bool)->Void) {
        if AppConfig.userHasOptedOut {
            Log.i("MRT -- Skipping registration as user has opted out of data reporting")
            callback(false)
            return
        }
        
        // Check they've turned notifs on or forget it...
        UNUserNotificationCenter.current().getNotificationSettings() {
            (settings:UNNotificationSettings) -> Void in
            
            // Start collecting the params to save to the DB (even if they dont qualify)
            var params = [String:Any]()
            var isEligible = true
            
            // CHECK: USER NOTIFS AUTH?
            
            let auth = settings.authorizationStatus
            params["eligible_notifs"] = (auth != .notDetermined && auth != .denied)
            if !(params["eligible_notifs"]! as! Bool) {
                Log.i("MRT -- User not valid for trial. Notification permissions not authorised.")
                isEligible = false
            }
            
            // CHECK: MRT TERMS ANSWERS?
            self.mrtTermsAnswers.forEach({ (key: String, value: Bool) in
                params["eligible_terms\(key.capitalized)"] = value
                isEligible = isEligible && value
            })
            
            // CHECK: AUDIT?
            let auditScore = AuditData.latest()!.auditScore
            params["audit"] = auditScore
            params["eligible_audit"] = auditScore >= self.MIN_AUDIT_SCORE
            if !(params["eligible_audit"]! as! Bool) {
                Log.i("MRT -- User not valid for trial. Audit score too low (\(auditScore))")
                isEligible = false
            }
            
            // CHECK: DEMOGRAPHIC?
            let user = DemographicData()
            params["age"] = user.age
            params["eligible_age"] = user.age >= 18
            if !(params["eligible_age"]! as! Bool) {
                Log.i("MRT -- User not valid for trial. Too young (\(user.age))")
                isEligible = false
            }
            params["eligible_isSerious"] = user.answer(questionId: "question9") as! Int == 0
            if !(params["eligible_isSerious"]! as! Bool) {
                Log.i("MRT -- User not valid for trial. User said 'just browsing')")
                isEligible = false
            }
            params["eligible_isUK"] = user.answer(questionId: "question5") as! Int == 0
            if !(params["eligible_isUK"]! as! Bool) {
                Log.i("MRT -- User not valid for trial. Not from UK")
                isEligible = false
            }
            
            // Choose the trial on registration
            if isEligible {
                var trial:String?
                trial = self.chooseRandom(weights: self.VERSION_PROBS)
                params["trialVersion"] = trial
                
                self.userDefs.set(trial, forKey:Keys.whichVersionKey)   // Note: this is used for userIsTrialParticipant bool propery
                Log.i("MRT -- User randomised to \(trial ?? "(nil)") trial")
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15.seconds, execute: {
//                    if Debug.ENABLED {
//                        AlertManager.forVC(<#T##vc: UIViewController##UIViewController#>).showSimpleAlert(title: nil, msg: "DEBUG: User randomised to \(trial ?? "(nil)") trial")
//                    }
//                })
            }
            
            // Trackin
            let timezoneStr = CalendarProvider.current.timeZone.identifier
            params["timezone"] = timezoneStr;
            params["deviceId"] = PXDeviceUID.uid();
            DataServer.shared.saveDataObject(className: self.ParticipantsTrackingClassName, objectId: nil, isUser: true, params: params, ensureSave: true, callback: nil)
            
            callback(isEligible)
            
        } // end notif auth check
    }
    
    //---------------------------------------------------------------------

    private func chooseRandom(weights:[String:Int]) -> String {
        // Get the total bucket size
        var total = 0
        weights.values.forEach { (ele) in
            total = total + ele
        }
        
        let random = Int.random(in: 1...total)
        rTally[random, default:0] += 1
        var accum = 0
        var chosen : String?
        for key in weights.keys.sorted() {
            let value = weights[key]!
            accum = accum + value
            if accum >= random {
                //Log.d("MRT - [rand] T=\(total) r=\(random) key=\(key) val=\(value) accum=\(accum)")
                chosen = key
                break
            }
        }
        
        return chosen!
    }
}
