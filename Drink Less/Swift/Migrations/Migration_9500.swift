//
//  Migrations_9300.swift
//  drinkless
//
//  Created by Hari Karam Singh on 15/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation

class Migration_9500: Migration {

    static func execute() -> [MigrationError]? {
        
        if !userHasCompletedOnboarding() {
            Log.i("Skipping migration as user hasn't finished onboarding")
            return nil
        }
        
        if let err = fixGoalDatesFromLastMigration() {
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

    // @see https://github.com/UCL-Centre-for-Behaviour-Change/DrinkLess/issues/9
    private static func fixGoalDatesFromLastMigration() -> MigrationError? {
        //return
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            NSException(name: NSExceptionName.genericException, reason: "We need an MOContext!", userInfo: nil).raise()
            return nil
        }
        
        let allGoals = PXGoal.allGoals(with: context)
        for goal in allGoals ?? [] {
            
//            let tz = NSTimeZone.appDefault()!
            let tz = Calendar.current.timeZone  // we need to use this one as its the one used by .startOfWeek()  @see https://github.com/UCL-Centre-for-Behaviour-Change/DrinkLess/issues/9
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
