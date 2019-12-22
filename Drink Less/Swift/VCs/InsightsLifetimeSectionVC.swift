//
//  InsightsLifetimeSectionVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 19/11/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit

class InsightsLifetimeSectionVC: InsightsSectionVCBase {

    //////////////////////////////////////////////////////////
    // MARK: - Types & Consts
    //////////////////////////////////////////////////////////
   
    final private let INTRINSIC_H_EXPANDED:CGFloat = 216
    final private let INTRINSIC_H_COMPACT:CGFloat = 122
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////

    @IBOutlet weak var daysSinceLbl: UILabel!
    @IBOutlet weak var daysSinceDateLbl: UILabel!
    @IBOutlet weak var unitsLbl: UILabel!
    @IBOutlet weak var alcFreeDaysLbl: UILabel!
    @IBOutlet weak var spentLbl: UILabel!
    @IBOutlet weak var caloriesLbl: UILabel!
    @IBOutlet weak var goalsHitLbl: UILabel!
    @IBOutlet weak var goalsNearLbl: UILabel!
    @IBOutlet weak var goalsMissedLbl: UILabel!
    
    
    // Formatters
    private var basicNF = { () -> NumberFormatter in
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
    private var currencyNF = { () -> NumberFormatter in
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
    private var dateFormatter = { () -> DateFormatter in
        let f = DateFormatter()
        f.calendar = CalendarProvider.current   // use our debug-able ones
        f.timeZone = TimeZoneProvider.current
        f.dateFormat = "d MMM Y"
        return f
    }()
    
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitsLbl.text = "0"
        alcFreeDaysLbl.text = "0"
        spentLbl.text = currencyNF.string(for: 0)
        caloriesLbl.text = "0"
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Subclass fulfillments
    //////////////////////////////////////////////////////////
    
    override func refresh() {

        let weekSumms:[PXWeekSummary] = allStatistics!.weeklySummaries as! [PXWeekSummary]

        /////////////////////////////////////////
        // Date labels
        /////////////////////////////////////////

        // use the first run. Weeksumm rounds back. Other option is first dirnk rec or alc free rec...
        let dateFirstUse = AppConfig.firstRunDate// weekSumms[0].startDate!
        let today:Date = NSDate.strictDateFromToday()!
        let daysSinceFirstUse = (fabs(dateFirstUse.timeIntervalSince(today)) / 3600.0 / 24.0).rounded()
        var stringToShow:String?
        //        if daysSinceFirstUse < 730 {
        stringToShow = basicNF.string(for: daysSinceFirstUse)! + " days since"
        //        }
        daysSinceLbl.text = stringToShow
        daysSinceDateLbl.text = dateFormatter.string(from: dateFirstUse)
        
        /////////////////////////////////////////
        // Drinking tallies
        /////////////////////////////////////////
        
        var drinkUnits:Float = 0
        var alcFreeDays:Float = 0
        var calories:Float = 0
        var spending:Float = 0
        
        for weekSumm in weekSumms {
            drinkUnits += Float(weekSumm.totalUnits)
            alcFreeDays += Float(weekSumm.alcoholFreeDays)
            calories += Float(weekSumm.totalCalories)
            spending += Float(weekSumm.totalSpending)
        }
        
        // We also need the drinks since the last week summary ended
        if let lastWeekSummEndDate = weekSumms.last?.endDate {
            let drinkRecs = PXDrinkRecord.fetchDrinkRecords(fromCalendarDate: lastWeekSummEndDate, toCalendarDate: Date.distantFuture, context: context) as! [PXDrinkRecord]
            for drinkRec in drinkRecs {
                drinkUnits += Float(drinkRec.totalUnits.floatValue)
                calories += Float(drinkRec.totalCalories.floatValue)
                spending += Float(drinkRec.totalSpending.floatValue)
            }
            
            let alcFreeRecs = PXAlcoholFreeRecord.fetchFreeRecords(fromCalendarDate: lastWeekSummEndDate, toCalendarDate: Date.distantFuture, context: context)!
            alcFreeDays += Float(alcFreeRecs.count)
        }
        
    
        // Write the labels...
        unitsLbl.text = basicNF.string(for: drinkUnits)
        alcFreeDaysLbl.text = basicNF.string(for: alcFreeDays)
        spentLbl.text = currencyNF.string(for: spending)
        caloriesLbl.text = basicNF.string(for: calories.rounded())
        
        
        /////////////////////////////////////////
        // Goal Tallies
        /////////////////////////////////////////
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            assert(false, "We need an MOContext!")
            return
        }
        
        var goalHits:Int = 0
        var goalNears:Int = 0
        var goalMisses:Int = 0
        let allGoals:[PXGoal] = PXGoal.allGoals(with: context)
        for goal in allGoals {
            let goalStats = PXGoalStatistics(goal: goal, region: .allCompleted)!
            goalHits += goalStats.exceedCount + goalStats.hitCount
            goalNears += goalStats.nearCount
            goalMisses += goalStats.missCount
        }
        
        goalsHitLbl.text = "\(goalHits) goal hits"
        goalsNearLbl.text = "\(goalNears) goal near hits"
        goalsMissedLbl.text = "\(goalMisses) goal misses"
    }
    
    override func sectionHeightForState(_ state: InsightsSectionState) -> CGFloat {
        return (state == .expanded) ? INTRINSIC_H_EXPANDED : INTRINSIC_H_COMPACT
    }
}
