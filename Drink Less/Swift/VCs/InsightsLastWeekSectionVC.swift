//
//  InsightsLastWeekSectionVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 09/10/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit

class InsightsLastWeekSectionVC: InsightsSectionVCBase, UITableViewDelegate, UITableViewDataSource {
    

    //////////////////////////////////////////////////////////
    // MARK: - Types & Consts
    //////////////////////////////////////////////////////////
    final private let DRINK_ICON_W:CGFloat = 14  // Fixed so they line up
    final private let DRINK_ICON_H:CGFloat = 20.0  // Fixed so they line up
    final private let DRINK_ICON_PAD_H:CGFloat = 1.0
    final private let DRINK_ICON_PAD_V:CGFloat = 3.0
    
    final private let INTRINSIC_H_EXPANDED:CGFloat = 293
    final private let INTRINSIC_H_COMPACT:CGFloat = 193
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Instance Vars
    //////////////////////////////////////////////////////////
    
    @IBOutlet weak var endingDateLbl: UILabel!
    @IBOutlet weak var unitsLbl: UILabel!
    @IBOutlet weak var spentLbl: UILabel!
    @IBOutlet weak var caloriesLbl: UILabel!
    @IBOutlet weak var alcFreeDaysLbl: UILabel!
    @IBOutlet weak var drinkIconsScrollView: UIScrollView!
    @IBOutlet weak var drinkIconsFirstRowStackView: UIStackView!
    @IBOutlet weak var drinkIconsSecondRowStackView: UIStackView!
    @IBOutlet weak var goalSummaryTable: UITableView!
    
    private var drinkIconsFadeLayer:CALayer?
    private var goalSummariesFadeLayer:CALayer?
    
    //---------------------------------------------------------------------
//    private var dateFormatter:DateFormatter = {
//        let f = DateFormatter()
//        f
//    }()
//    
    private var calorieFormatter:NumberFormatter = {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.maximumFractionDigits = 0
        return n
    }()
    private var currencyFormatter:NumberFormatter = {
        let n = NumberFormatter()
        n.numberStyle = .currency
        return n
    }()
    private var dateFormatter:DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM"
        return df
    }()
    
    
    struct GoalSummary {
        var icon:UIImage!
        var title:String!
    }
    
    private var goalSummaries = [GoalSummary]()
    
    private var lastWeekSummary:PXWeekSummary?
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        // Zero out everything
        self.unitsLbl.text = "0"
        self.alcFreeDaysLbl.text = "0"
        self.spentLbl.text = currencyFormatter.string(from: 0)
        self.caloriesLbl.text = "0"
        // Clear out debugging colors
        self.drinkIconsFirstRowStackView.backgroundColor = .clear
        self.drinkIconsSecondRowStackView.backgroundColor = .clear
    }
    
    //---------------------------------------------------------------------

    override func refresh() {
        goalSummaries.removeAll()
        
        guard let lastWeekSummary = self.allStatistics!.lastWeekSummary else {
            Log.i("No last week summary yet...")
            endingDateLbl.text = "pending..."
            return
        }
        self.lastWeekSummary = lastWeekSummary
        
        // Set date in the header
        endingDateLbl.text = "Ending "  + self.dateFormatter.string(from: lastWeekSummary.endDate! - 1.days)
        
        // Set the number stats
        self.unitsLbl.text = String(format: "%.0f", lastWeekSummary.totalUnits)
        self.alcFreeDaysLbl.text = "\(lastWeekSummary.alcoholFreeDays)"
        self.spentLbl.text = self.currencyFormatter.string(from: NSNumber(floatLiteral: Double(lastWeekSummary.totalSpending)))
        self.caloriesLbl.text = self.calorieFormatter.string(from: NSNumber(floatLiteral:Double(lastWeekSummary.totalCalories)))
        
        self.layoutDrinkIconsScroller()
        
        // Gather data for the goals table
        let ctx = PXCoreDataManager.shared()!.managedObjectContext
        if let goals = PXGoal.activeGoals(with: ctx) {
            for goal in goals {
                let stats = PXGoalStatistics(goal: goal, region: PXStatisticRegion.lastCompleted)!
                let summary = GoalSummary(icon: stats.icon, title: stats.shortTitle)
                goalSummaries.append(summary)
            }
        }
        
        self.goalSummaryTable.reloadData()
    }
    
    //---------------------------------------------------------------------

    private func layoutDrinkIconsScroller() {
        
        // Clear out residual
        for v in drinkIconsFirstRowStackView.arrangedSubviews {
            v.removeFromSuperview()
        }
        for v in drinkIconsSecondRowStackView.arrangedSubviews {
            v.removeFromSuperview()
        }
        
        
        // Layout the scrollview.  Figure out how man per row
        guard let stats = self.lastWeekSummary else {
            return // not enough data
        }

        let maxPerRow:Int = Int(floor(drinkIconsScrollView.width / DRINK_ICON_W))
        var numInFirstRow:Int = 0
        var numInSecondRow:Int = 0
        // we want the units, not the entries count
        let drinksCnt = stats.drinkRecords!.reduce(0){ (tally, next) -> Int in
            let rec = next as! PXDrinkRecord
            let q = rec.quantity.intValue
            return tally + q
        }
        
        if drinksCnt <= maxPerRow {
            numInFirstRow = drinksCnt
        } else if drinksCnt <= maxPerRow * 2 {
            numInFirstRow = maxPerRow
            numInSecondRow = drinksCnt - numInFirstRow
        } else {
            // divide them evenly with +1 in the top for odd counts
            numInFirstRow = Int(ceil(Float(drinksCnt) / 2.0))
            numInSecondRow = Int(floor(Float(drinksCnt) / 2.0))
        }
        
        // Now lay them out place them
        var i = 0 // drink rec index
        var cnt = 0  // drink count
        var leftOver = 0
        while cnt < numInFirstRow {
            let drinkRec = stats.drinkRecords[i] as! PXDrinkRecord
            let quantity = drinkRec.quantity.intValue
            for j in 0..<quantity {
                let icon = UIImageView(image: UIImage(named: drinkRec.iconName))
                icon.sizeToFit()
                icon.contentMode = .scaleAspectFill
                icon.addConstraint(NSLayoutConstraint(item: icon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: DRINK_ICON_W))
                drinkIconsFirstRowStackView.addArrangedSubview(icon)
                cnt += 1
                // have we crossed the line mid-drink-entry?
                if cnt >= numInFirstRow {
                    leftOver = quantity - j - 1
                    break;
                }
            }
            if leftOver == 0 {
                i += 1
            }
        }
        // Filler if less than maxPerRow
        if numInFirstRow < maxPerRow {
            for _ in 0..<(maxPerRow-numInFirstRow) {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: DRINK_ICON_W, height: DRINK_ICON_H))
                v.addConstraint(NSLayoutConstraint(item: v, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: DRINK_ICON_W))                
                drinkIconsFirstRowStackView.addArrangedSubview(v)
            }
        }
        
        
        cnt = 0
        while cnt < numInSecondRow {
            let drinkRec = stats.drinkRecords[i] as! PXDrinkRecord
            let quantity = drinkRec.quantity.intValue
            let loopCnt = leftOver > 0 ? leftOver : quantity
            leftOver = 0
            for _ in 0..<loopCnt {
                let icon = UIImageView(image: UIImage(named: drinkRec.iconName))
                icon.sizeToFit()
                icon.contentMode = .scaleAspectFill
                icon.addConstraint(NSLayoutConstraint(item: icon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: DRINK_ICON_W))
                drinkIconsSecondRowStackView.addArrangedSubview(icon)
                cnt += 1
            }
            i += 1
        }
        
        // Add some filler to the bottom row
        for _ in 0..<max(0, maxPerRow - numInSecondRow) {
            let v = UIView()
            v.addConstraint(NSLayoutConstraint(item: v, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: DRINK_ICON_W))
            v.addConstraint(NSLayoutConstraint(item: v, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 3))
            v.backgroundColor = .clear
            drinkIconsSecondRowStackView.addArrangedSubview(v)
        }
        
        
        // Add a grad fader
        if drinkIconsFadeLayer != nil {
            drinkIconsFadeLayer?.removeFromSuperlayer()
        }
        if numInFirstRow > maxPerRow {
            drinkIconsFadeLayer = whiteFadeLayer(referenceView: drinkIconsScrollView, percentSize: 0.22)
            let superv = drinkIconsScrollView.superview!
            
            drinkIconsFadeLayer!.frame = drinkIconsScrollView.convert(drinkIconsFadeLayer!.frame, to: superv)
            
            superv.layer.addSublayer(drinkIconsFadeLayer!)
        }
    }
    
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Subclass fulfillments
    //////////////////////////////////////////////////////////
    
    override func sectionHeightForState(_ state: InsightsSectionState) -> CGFloat {
        return state == .expanded ? INTRINSIC_H_EXPANDED : INTRINSIC_H_COMPACT
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Table, and other fulfillments
    //////////////////////////////////////////////////////////

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goalSummaries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GoalSummaryCell")!
        let goal = goalSummaries[indexPath.row]
        let icon = cell.viewWithTag(101) as! UIImageView
        let lbl = cell.viewWithTag(102) as! UILabel
        lbl.text = goal.title
        icon.image = goal.icon
        
        return cell
    }
    
    //---------------------------------------------------------------------

    /** Defaults to right side */
    private func whiteFadeLayer(referenceView:UIView, percentSize:CGFloat, toBottom:Bool=false) -> CALayer {
        let view = referenceView
        let gradLayer = CAGradientLayer()
        gradLayer.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor.white.cgColor]
        gradLayer.startPoint = CGPoint(x: 0, y: 0)
        gradLayer.endPoint = CGPoint(x: toBottom ? 0 : 1, y: toBottom ? 1 : 0)
        gradLayer.locations = [0, 1]
        let x = toBottom ? 0 : view.width - view.width * percentSize
        let y = toBottom ? view.height - view.height * percentSize : 0
        let w = toBottom ? view.width : view.width * percentSize
        let h = toBottom ? view.height * percentSize : view.height
        gradLayer.frame = CGRect(x: x, y: y, width: w, height: h)
        return gradLayer
    }
}
