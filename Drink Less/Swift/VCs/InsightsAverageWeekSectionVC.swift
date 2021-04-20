//
//  InsightsAverageWeekSectionVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 28/10/2019.
//  Copyright © 2019 UCL. All rights reserved.
//

import UIKit
//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

class InsightsAverageWeekSectionVC: InsightsSectionVCBase, PXItemListVCDelegate {
    
    //////////////////////////////////////////////////////////
    // MARK: - Types & Consts
    //////////////////////////////////////////////////////////
    final private let INTRINSIC_H_EXPANDED:CGFloat = 300
    final private let INTRINSIC_H_COMPACT:CGFloat = 186
    
    
    struct WeeklyAverage {
        var timeRange:InsightsAverageWeekGraphRange = InsightsAverageWeekGraphRange1Month
        var drinkUnitsAvg:Float = 0
        var alcFreeDaysAvg:Float = 0
        var caloriesAvg:Float = 0
        var spendingAvg:Float = 0
    }
    
    //////////////////////////////////////////////////////////
    // MARK: -
    //////////////////////////////////////////////////////////
/*
     { weekEnding: Date,
     alcFree: 3,
     drinkUnits: 4
     
 */
    
    @IBOutlet weak var dataWarningOverlay: UIView!
    @IBOutlet weak var timeRangeSelectorBtn: UIButton!
    @IBOutlet weak var timeRangeLabel: UILabel!
    @IBOutlet weak var graphView: InsightsAverageWeekGraphView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var drankLbl: UILabel!
    @IBOutlet weak var consumedLbl: UILabel!
    @IBOutlet weak var spentLbl: UILabel!
    @IBOutlet weak var alcFreeDaysLbl: UILabel!
    
    
    private var currentTimeRange: InsightsAverageWeekGraphRange {
        get {
    
            if let obj:NSNumber = UserDefaults.standard.object(forKey: "InsightsAverageWeekSectionVC.currentTimeRange") as? NSNumber {
                return InsightsAverageWeekGraphRange(UInt(obj.intValue))
            }
            else {
                return InsightsAverageWeekGraphRange1Month
            }
        }
        set {
            let obj = NSNumber(integerLiteral: Int(newValue.rawValue))
            UserDefaults.standard.set(obj, forKey: "InsightsAverageWeekSectionVC.currentTimeRange")
        }
    }
    
    private var timeRangeEnums = [InsightsAverageWeekGraphRange1Month, InsightsAverageWeekGraphRange3Months, InsightsAverageWeekGraphRange6Months, InsightsAverageWeekGraphRange1Year, InsightsAverageWeekGraphRangeLifetime]
    private var timeRangeLabels = ["1 month", "3 months", "6 months", "1 year", "Lifetime"]
    
    private var timeRangeSelectorPopoverVC:PopoverVC?
    
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
    
    
    //////////////////////////////////////////////////////////
    // MARK: -
    //////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //---------------------------------------------------------------------

    override func viewWillAppear(_ animated: Bool) {
    }
    
    //---------------------------------------------------------------------
    
    // Recalculate the averages and refresh the view components
    override func refresh() {
        
        
        /////////////////////////////////////////
        // TIME RANGE LABEL AND DESCR TEXT
        /////////////////////////////////////////
        
        timeRangeLabel.text = timeRangeLabels[timeRangeEnums.firstIndex(of: currentTimeRange)!]
        
        // The descriptive text
        var timeText = ""
        var fullText = ""
        if currentTimeRange == InsightsAverageWeekGraphRangeLifetime {
            timeText = "since you began"
            fullText = "In an average week \(timeText), you've…"
        } else {
            if currentTimeRange == InsightsAverageWeekGraphRange1Year {
                timeText = "year"  // a little nicer than "over the last 1 year"
            } else {
                timeText = timeRangeLabels[timeRangeEnums.firstIndex(of:currentTimeRange)!]
            }
            fullText = "In an average week over the last \(timeText) you've…"
        }
        // Bold the time text
        //        let attribs = descriptionLbl.attributedText!.attributes(at: 0, effectiveRange: nil)
        //        let defaultFont = attribs[NSFontAttributeName]! as! UIFont
        let size = CGFloat(20) //defaultFont.pointSize
        let mediumFont = UIFont(name: "HelveticaNeue-Medium", size: size)
        let attribText = NSMutableAttributedString(string: fullText)
        let r = fullText.range(of: timeText)!
        let boldRange = NSMakeRange(r.lowerBound.encodedOffset, r.upperBound.encodedOffset - r.lowerBound.encodedOffset)
        attribText.addAttributes([NSAttributedString.Key.font: mediumFont!], range: boldRange)
        descriptionLbl.attributedText = attribText
        
        
        
        /////////////////////////////////////////
        // STATS
        /////////////////////////////////////////
        
        // Check we've got enough data for this range first
        let hasCoverage = hasDataCoverageForStatsTimeRange()
        dataWarningOverlay.isHidden = hasCoverage
        
        if !hasCoverage {
            Log.d("Not enough time has lapsed to render Average section.")
            // Blank out our numeric values
            drankLbl.text = "0"
            consumedLbl.text = "0"
            spentLbl.text = currencyNF.string(for: 0.00)
            alcFreeDaysLbl.text = "0"
            return
        }
        
        
        
        let weekAvg = calculateWeeklyAverage()

        // Assign our numeric values
        drankLbl.text = basicNF.string(for: weekAvg.drinkUnitsAvg)
        consumedLbl.text = basicNF.string(for: weekAvg.caloriesAvg)
        spentLbl.text = currencyNF.string(for: weekAvg.spendingAvg)
        alcFreeDaysLbl.text = basicNF.string(for: (weekAvg.alcFreeDaysAvg))
        
        /////////////////////////////////////////
        // GRAPH
        /////////////////////////////////////////
        
        // Assign the graph data
        graphView.graphRange = currentTimeRange
        graphView.allStats = self.allStatistics!
        graphView.drinkUnitsAverage = CGFloat(weekAvg.drinkUnitsAvg)
        graphView.alcFreeDaysAverage = CGFloat(roundf(weekAvg.alcFreeDaysAvg))
        graphView.redraw()
    }
    //////////////////////////////////////////////////////////
    // MARK: - Subclass fulfillments
    //////////////////////////////////////////////////////////
    
    override func sectionHeightForState(_ state: InsightsSectionState) -> CGFloat {
        return state == .expanded ? INTRINSIC_H_EXPANDED : INTRINSIC_H_COMPACT
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Touch Reporting
    //////////////////////////////////////////////////////////

    
    public var onGraphTouchDidBegin: ()->Void = {} {
        didSet {
            self.graphView.hostingView.onGraphTouchDidBegin = onGraphTouchDidBegin
            
        }
    }
    public var onGraphTouchDidEnd: ()->Void = {} {
        didSet {
            self.graphView.hostingView.onGraphTouchDidEnd = onGraphTouchDidEnd
        }
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    private func hasDataCoverageForStatsTimeRange() -> Bool {
//        guard let lastWeekEndDate = allStats.weeklySummaries.last else {
//            return false
//        }
//
        // Let's make this simple. The weeklySummaries: skip the first and the last as they are incomplete weeks (unless they began at / it is currently midnight monday!). Ensure there are enough entries/weeks remaining
        let weeksRequired = minWeekCountForTimeRange(timeRange: currentTimeRange)
        return (self.allStatistics!.weeklySummaries.count - 2) >= weeksRequired
    }
    
    //---------------------------------------------------------------------

    private func calculateWeeklyAverage() -> WeeklyAverage {
        // As above keep this simple. Use whole weeks and the (pretty close) approx of
        var weeksBack:UInt = 0
        if currentTimeRange == InsightsAverageWeekGraphRangeLifetime {
            weeksBack = UInt(allStatistics!.weeklySummaries.count - 2)  // minimum has already been validated
        } else {
            weeksBack = minWeekCountForTimeRange(timeRange: currentTimeRange)
        }
        
        var weeksAvg = WeeklyAverage()
        weeksAvg.timeRange = currentTimeRange

        // We want to zero the numbers until we have at least a full week to go on
        if allStatistics!.weeklySummaries.count - 2 < weeksBack {
            return weeksAvg; // zeroed
        }
        
        // Get the right slice
        let weeksCnt = self.allStatistics!.weeklySummaries.count
        let r0 = Int(weeksCnt) - Int(weeksBack) - 1   // back one more for 0 indexing. remember 1st and last week summ are incomplete.
        let r1 = Int(weeksCnt) - 1 - 1
        let weekSummsToAverage:Array<PXWeekSummary> = Array(allStatistics!.weeklySummaries[r0...r1]) as! Array<PXWeekSummary>
        // Sum then divide
        for weekSumm in weekSummsToAverage {
            weeksAvg.drinkUnitsAvg += Float(weekSumm.totalUnits)
            weeksAvg.alcFreeDaysAvg += Float(weekSumm.alcoholFreeDays)
            weeksAvg.caloriesAvg += Float(weekSumm.totalCalories)
            weeksAvg.spendingAvg += Float(weekSumm.totalSpending)
        }
        weeksAvg.drinkUnitsAvg /= Float(weekSummsToAverage.count)
        weeksAvg.alcFreeDaysAvg /= Float(weekSummsToAverage.count)
        weeksAvg.caloriesAvg /= Float(weekSummsToAverage.count)
        weeksAvg.spendingAvg /= Float(weekSummsToAverage.count)
        
        return weeksAvg
    }
    
    //---------------------------------------------------------------------

    private func minWeekCountForTimeRange(timeRange: InsightsAverageWeekGraphRange) -> UInt {
        if timeRange == InsightsAverageWeekGraphRangeLifetime {
            return 52 // 9 months BUT the view portal is larger (12 months) --- didnt work
        } else {
            return InsightsAverageWeekGraphView.viewRangeInWeeks(forTime: timeRange);
        }
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Handlers & Delegates
    //////////////////////////////////////////////////////////
    
    // should be called "handleRangeSelectorTouched"
    @IBAction func handleRangeSelectorChanged(_ buttonView:UIView) {
        // Make selector list
        let itemListVC = PXItemListVC(nibName: "PXItemListVC", bundle: nil)
        itemListVC.itemsArray = timeRangeLabels
        itemListVC.selectedIndex = timeRangeEnums.firstIndex(of:currentTimeRange)!
        itemListVC.delegate = self
        
        // Wrap and present it
        let size = CGSize(width: 200, height: 55 * (timeRangeLabels.count - 1))
        let r = CGRect(x:0, y:buttonView.frame.origin.y, width:buttonView.frame.size.width, height:buttonView.frame.size.height);
        
        timeRangeSelectorPopoverVC = PopoverVC(contentVC: itemListVC, preferredSize: size, sourceView: buttonView, sourceRect: r)
            
        present(timeRangeSelectorPopoverVC!, animated: true, completion: nil)
    }
    
    //---------------------------------------------------------------------

    func itemListVC(_ itemListVC: PXItemListVC!, chosenIndex: Int) {
        // Update everything
        currentTimeRange = timeRangeEnums[chosenIndex]
        refresh()
        timeRangeSelectorPopoverVC?.dismiss(animated: true, completion: nil)
    }
}
