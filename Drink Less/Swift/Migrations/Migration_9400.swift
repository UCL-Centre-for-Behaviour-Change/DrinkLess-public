//
//  Migrations_9300.swift
//  drinkless
//
//  Created by Hari Karam Singh on 15/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation

class Migration_9400: Migration {

    static func execute() -> [MigrationError]? {
        
        if !userHasCompletedOnboarding() {
            Log.i("Skipping migration as user hasn't finished onboarding")
            return nil
        }
        
        if let err = migrateDemographicDataFromIntroDataFile() {
            return [err]
        }
        if let err = migrateFirstAuditDataFromIntoDataFile() {
            return [err]
        }
        
        if let err = migrateFollowUpEntry() {
            return [err]
        }
        
        if let err = migrateUserOptOut() {
            return [err]
        }
        
        if let err = fixGoalDates() {
            return [err]
        }
        
        
        return nil
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    /**
     Check whether the user is half-way through onboarding and if so we can just skip the migration
     - Note, firstRun check has already been done by MigrationManager
     - Note the new verison of the app starts over if they havent finished. If it resumed like before (between app kills) then this would be a problem because the demog and first audit data are written in the middle of the sequence, not at the end.
     */
    private static func userHasCompletedOnboarding() -> Bool {
        return PXIntroManager.shared()!.stage == PXIntroStage.finished
    }

    //---------------------------------------------------------------------

    private static func migrateDemographicDataFromIntroDataFile() -> MigrationError? {
        Log.i("migrateDemographicDataFromIntroDataFile()")

        guard let introMan = PXIntroManager.shared(), introMan.demographicsAnswers.count > 0 else {
            return MigrationError("Can't load old PXIntroMan data")
        }
        
        if let dict = introMan.demographicsAnswers as? [String:NSObject] {
            let demoData = DemographicData()
            for entry in dict {
                demoData.setAnswer(questionId: entry.key, answerValue: entry.value)
            }
            demoData.save(localOnly:true)
            Log.i("Successfully ported demographic data: \(dict)")
            
        } else {
            return MigrationError("Demographic data missing from intro.data!")
        }
        
        Log.i("migrateDemographicDataFromIntroDataFile() success!")
        return nil;
    }
    
    //---------------------------------------------------------------------

    private static func migrateFirstAuditDataFromIntoDataFile() -> MigrationError? {
        Log.i("migrateFirstAuditDataFromIntoDataFile()")
        
        guard let introMan = PXIntroManager.shared(), introMan.demographicsAnswers.count > 0 else {
            return MigrationError("Can't load old PXIntroMan data")
        }
        
        guard let auditAnswers = introMan.auditAnswers as? [String:NSNumber],
            let estimateAnswers = introMan.estimateAnswers as? [String:NSNumber],
            let actualAnswers = introMan.actualAnswers as? [String:NSNumber],
            let auditScore = introMan.auditScore as? NSNumber else {
            
            return MigrationError("Can't parse audit data from old PXIntroMan data.")
        }
        
        let auditData = AuditData()
        for entry in auditAnswers {
            auditData.setAnswer(questionId: entry.key, answerValue: entry.value)
        }
        
        for entry in estimateAnswers {
            if entry.key.contains("all-UK") {
                auditData.countryEstimate = entry.value.floatValue
            } else {
                auditData.demographicEstimate = entry.value.floatValue
                if let idx = entry.key.lastIndex(of: ":") {
                    auditData.demographicKey = entry.key.substring(to: idx)
                } else {
                    return MigrationError("Demographic key missing from audit data!")
                    
                }
            }
        }
    
        for entry in actualAnswers {
            if entry.key.contains("all-UK") {
                if entry.key.contains("Drinkers") {
                    auditData.countryDrinkersActual = entry.value.floatValue
                } else {
                    auditData.countryActual = entry.value.floatValue
                }
            } else {
                if entry.key.contains("Drinkers") {
                    auditData.demographicDrinkersActual = entry.value.floatValue
                } else {
                    auditData.demographicActual = entry.value.floatValue
                }
            }
        }
    
        auditData.auditScore = auditScore.intValue
        
        // Calculate new auditC score but preserve old auditScore
        let oldScore = auditData.auditScore
        auditData.calculateAuditScores(isOnboarding: true)
        auditData.auditScore = oldScore

        // Get the date from the first run date
        let defs = UserDefaults.standard
        if let date = defs.object(forKey: "firstRun") as? NSDate {
            auditData.date = date
        } else {
            // I suppose better than nothing
            auditData.date = NSDate()
            Log.w("First run date not found. Using today!")
        }
        
        // Set the timezone to the default one
        auditData.timezone = NSTimeZone.appDefault()
        
        auditData.save()
        auditData.oldSaveToParseUser()  // adds auditCScore
        
        Log.i("Success \(auditData.debugDescription) !!")
        
        Log.i("migrateFirstAuditDataFromIntoDataFile() success!")
        return nil;
    }
    
    //---------------------------------------------------------------------

    private static func migrateFollowUpEntry() -> MigrationError? {
        guard let parseUser = PFUser.current() else {
            assertionFailure("Should have a parse user prior to calling this migration.")
            return nil
        }
        
        guard let latestAudioData = AuditData.latest() else {
            assertionFailure("Should have an AuditData in the Db already")
            return nil
        }
        
        Log.i("migrateFollowUpEntry")
        Log.i("Fetching parse object for user id \(String(describing: parseUser.objectId))...")
        let query = PFQuery(className: "PXFollowUp");
        query.whereKey("Author", equalTo: parseUser)
        query.findObjectsInBackground { (matches:[PFObject]?, err:Error?) in
            // Error and none found (which is ok)
            if let e = err {
                Log.e("Error fetching PXFollowUp entry for user. \(e)")
                DataServer.shared.logError("Migration_9400", msg: "Error fetching PXFollowUp entry for user.", info: ["error": e])
                // Sadly can't report this to the UI tier given our migration sytem at the moment
                return;
            }
            
            guard let followUp = matches?.first else {
                Log.i("FollowUp entry not found. Migration complete.")
                return
            }
            
            Log.i("Found FollowUp entry: \(String(describing:followUp))")
            
            let auditData = AuditData()
            auditData.auditScore = (followUp["NewScore"] as! NSNumber).intValue
            auditData.demographicKey = latestAudioData.demographicKey
            auditData.countryEstimate = latestAudioData.countryEstimate
            auditData.demographicEstimate = latestAudioData.demographicEstimate
            
            // Calculate new auditC score but preserve old auditScore
            let oldScore = auditData.auditScore
            auditData.calculateAuditScores(isOnboarding: false)
            auditData.auditScore = oldScore
            
            // Needs AuditCScore!  Fails silently for some reason??
            auditData.calculateActualPercentiles()
            auditData.timezone = NSTimeZone.appDefault()
            guard let date = followUp.createdAt else {
                Log.e("PXFollowUp entry has no createdDate ???");
                return
            }
            auditData.date = date as NSDate // parse date
            auditData.setAnswer(questionId: "question1", answerValue: followUp["questionnaireScreen1Question0"] as! NSNumber)
            auditData.setAnswer(questionId: "question2", answerValue: followUp["questionnaireScreen1Question1"] as! NSNumber)
            auditData.setAnswer(questionId: "question3", answerValue: followUp["questionnaireScreen1Question2"] as! NSNumber)
            auditData.setAnswer(questionId: "question4", answerValue: followUp["questionnaireScreen3Question0"] as! NSNumber)
            auditData.setAnswer(questionId: "question5", answerValue: followUp["questionnaireScreen3Question1"] as! NSNumber)
            auditData.setAnswer(questionId: "question6", answerValue: followUp["questionnaireScreen3Question2"] as! NSNumber)
            auditData.setAnswer(questionId: "question7", answerValue: followUp["questionnaireScreen3Question3"] as! NSNumber)
            auditData.setAnswer(questionId: "question8", answerValue: followUp["questionnaireScreen3Question4"] as! NSNumber)
            auditData.setAnswer(questionId: "question9", answerValue: followUp["questionnaireScreen3Question5"] as! NSNumber)
            auditData.setAnswer(questionId: "question10", answerValue: followUp["questionnaireScreen3Question6"] as! NSNumber)
            
            // Right. Save. Locally and in parse
            auditData.save()
            Log.i("Saved as AuditData entry. Migration complete.")
            
        }

        return nil
    }
 
    //---------------------------------------------------------------------

    private static func migrateUserOptOut() -> MigrationError? {
        Log.i("migrateUserOptOut()")
        guard let user = PFUser.current() else {
            Log.w("No parse user found")
            return nil
        }
        
        let optedOut = (user["hasOptedOut"] as? Bool) ?? false
        Log.i("Migrating parse opt out value of '\(optedOut ? "true":"false")' to AppConfig")
        AppConfig.userHasOptedOut = optedOut
        DataServer.shared.isEnabled = !optedOut
        
        return nil
    }
    
    //---------------------------------------------------------------------

    private static func fixGoalDates() -> MigrationError? {
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            NSException(name: NSExceptionName.genericException, reason: "We need an MOContext!", userInfo: nil).raise()
            return nil
        }
        
        let allGoals = PXGoal.allGoals(with: context)
        for goal in allGoals ?? [] {
            
            let tz = NSTimeZone.appDefault()!
            goal.timezone = tz.identifier
            
            let roundedDate = { (date:Date)->Date in
                let dateBack = (date as NSDate).startOfWeek()!
                let dateForward = NSDate.change(dateBack, byDays: 7)!
                let backDiff = abs(NSDate.daysBetweenDate(date, andDate: dateBack))
                let forwardDiff = abs(NSDate.daysBetweenDate(date, andDate: dateForward))
                let newDate = backDiff < forwardDiff ? dateBack : dateForward
                Log.i("Rounding goal date: orig=\(date) new=\(newDate) back=\(dateBack)(±\(backDiff)) forward=\(dateForward)(±\(forwardDiff))")
                return newDate
            }
            if let startDate = goal.startDate {
                Log.i("Checking goal startDate...")
                goal.startDate = roundedDate(startDate)
            }
            if let endDate = goal.endDate {
                Log.i("Checking goal endDate...")
                goal.endDate = roundedDate(endDate)
            }
        }
        
        // Fail silently. Not worth an alert really
        try? context.save()
        
        return nil
    }
    
}
