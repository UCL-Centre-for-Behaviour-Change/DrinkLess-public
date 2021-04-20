//
//  InsightsVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 03/10/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit


class InsightsVC: PXTrackedViewController {

    //////////////////////////////////////////////////////////
    // MARK: - Types & Consts
    //////////////////////////////////////////////////////////

    final private var BUSY_OVERLAY_ALPHA = CGFloat(0.5)

    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var sectionHeightConstraints:[NSLayoutConstraint]!
    
    private var allStatistics:PXAllStatistics?
    
    private var sectionVCs = [InsightsSectionVCBase]()
    private var sectionState:InsightsSectionState {
        get {
            let val = UserDefaults.standard.integer(forKey: "InsightsVC.sectionState")
            return InsightsSectionState(rawValue: val)!
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "InsightsVC.sectionState")
        }
    }
    
    lazy private var spinnerView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.hidesWhenStopped = false
        v.style = .whiteLarge
        return v
    }()
    lazy private var busyIndicatorOverlay:UIView = {
        let cont = UIView(frame: self.view.bounds)
        cont.backgroundColor = UIColor.lightGray
        cont.isUserInteractionEnabled = false
        cont.isOpaque = false
        cont.alpha = self.BUSY_OVERLAY_ALPHA
        let spinner = self.spinnerView
        cont.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        let horizC = NSLayoutConstraint(item: spinner, attribute: .centerX, relatedBy: .equal, toItem: cont, attribute: .centerX, multiplier: 1, constant: 0)
        let vertC = NSLayoutConstraint(item: spinner, attribute: .centerY, relatedBy: .equal, toItem: cont, attribute: .centerY, multiplier: 1, constant: 0)
        cont.addConstraints([horizC, vertC])
        return cont
    }()
    
    private var averageWeekSectionVC:InsightsAverageWeekSectionVC? {
        get  {
            for vc in sectionVCs {
                if let theVC = vc as? InsightsAverageWeekSectionVC {
                    return theVC
                }
            }
            return nil
        }
    }
    
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "Insights"
        
        averageWeekSectionVC!.onGraphTouchDidBegin = {
            self.scrollView.isScrollEnabled = false
        }
        averageWeekSectionVC!.onGraphTouchDidEnd = {
            self.scrollView.isScrollEnabled = true
        }
        
        self.view.tag = 440; // prevent tool tip (got to change this horrible hack)
    }

    //---------------------------------------------------------------------

    // Reload everytime we come to the view
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshStatsAndViews()
        
        // Resize to the correct size
        updateSectionHeights()
        setNavCollapseIconTo(state: sectionState)
        
        PXDailyTaskManager.shared().completeTask(withID:"insights")
        
    }
    
    //---------------------------------------------------------------------

    private func refreshStatsAndViews() {
        Log.i("Re-loading AllStatistics in background...")
        // Load Allstats in the BG and assign when ready
        showBusyIndicator()
        DispatchQueue.global(qos: .userInitiated).async {
            self.allStatistics = PXAllStatistics()
            DispatchQueue.main.async {
                self.hideBusyIndicator()
                for sectionVC in self.sectionVCs {
                    sectionVC.allStatistics = self.allStatistics
                }
            }
        }
    }
    

    private func showBusyIndicator() {
        let parentView = self.view!
        busyIndicatorOverlay.alpha = 0
        parentView.addSubview(busyIndicatorOverlay)
        UIView.animate(withDuration: 0.3) {
            self.busyIndicatorOverlay.alpha = self.BUSY_OVERLAY_ALPHA
        }
        spinnerView.startAnimating()
    }
    
    private func hideBusyIndicator() {
        UIView.animate(withDuration: 0.3, animations: {
            self.busyIndicatorOverlay.alpha = 0
        }) { (completed:Bool) in
            self.busyIndicatorOverlay.removeFromSuperview()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sectionVC = segue.destination as? InsightsSectionVCBase {
            sectionVCs.append(sectionVC)
        }
    }

    @IBAction func handleExpandCollapse(_ sender: Any) {
        let newState = (sectionState == .collapsed ? InsightsSectionState.expanded : InsightsSectionState.collapsed)
        
        setNavCollapseIconTo(state: newState)
        sectionState = newState
        
        // Animate new sizes
        UIView.animate(withDuration: 0.5) {
            self.updateSectionHeights()
        }
        
    }
    
    private func updateSectionHeights() {
        for i in 0..<self.sectionVCs.count {
            let sectionVC = self.sectionVCs[i]
            let constraint = self.sectionHeightConstraints[i]
            let newH = sectionVC.sectionHeightForState(sectionState)
            
            constraint.constant = newH
            let v:UIView = constraint.firstItem as! UIView
            //                v.setNeedsUpdateConstraints()
            //                 v.updateConstraints()
            v.setNeedsLayout()
        }
        self.view.layoutIfNeeded()
    }
    
    private func setNavCollapseIconTo(state:InsightsSectionState) {
        // Update Nav bar icon
        let iconName = "insights-" + (state == .collapsed ? "expand" : "collapse") + "-icon"
        self.navigationItem.rightBarButtonItem!.image = UIImage(named:iconName)
    }

    
}
