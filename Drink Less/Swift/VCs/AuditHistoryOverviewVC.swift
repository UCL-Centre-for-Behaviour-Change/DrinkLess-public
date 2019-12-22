//
//  AuditHistoryOverviewVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 04/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit
@objc
class AuditHistoryOverviewVC: PXTrackedViewController, AuditHistoryTableViewDelegate {
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Types & Consts
    //////////////////////////////////////////////////////////
    
    // To use in the main gauge
    private let POPULATION_TYPE = GroupData.PopulationType.demographic
    private let GROUP_TYPE = GroupData.GroupType.everyone
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    
    @IBOutlet weak var gaugeView: PXGaugeView!
    @IBOutlet weak var auditHistoryTable: AuditHistoryTableView!
    @IBOutlet weak var whoComparedInfoBtn: UIButton!
    
    private let lastestAuditData:AuditData
    private let originalAuditData:AuditData?
    private let allAuditData:[AuditData]
    private let helper:PXAuditFeedbackHelper
    private var whoComparesVC:UIViewController?
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    @objc class func instantiateFromStoryboard() -> AuditHistoryOverviewVC {
        let sb = UIStoryboard(name: "Activities", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "AuditHistoryOverviewVC") as! AuditHistoryOverviewVC
        return vc
    }
    
    //---------------------------------------------------------------------
    
    required init?(coder aDecoder: NSCoder) {
        helper = PXAuditFeedbackHelper(demographicData:VCInjector.shared.demographicData)
        lastestAuditData = AuditData.latest()! // @TODO: Error checking
        let all = AuditData.allSortedByCalendarDate(descending: true)! // @TODO error checking
        allAuditData = all
        if all.count > 1 {
            originalAuditData = AuditData.first()
        } else {
            originalAuditData = nil
        }
        super.init(coder: aDecoder)
        screenName = "Audit History Overview" // for tracking
    }
    
    //---------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Your Drinking Review"
        self.view.backgroundColor = UIColor.white
    }

    //---------------------------------------------------------------------

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        /////////////////////////////////////////
        // GAUGE
        /////////////////////////////////////////
        
        gaugeView.isEditing = false
        gaugeView.percentileColors = self.helper.percentileColors;
        gaugeView.percentileZones = self.helper.percentileGaugeZones;
        gaugeView.estimate = CGFloat(lastestAuditData.demographicEstimate)
        gaugeView.percentile = CGFloat(lastestAuditData.actualPercentile(groupType: GROUP_TYPE, populationType: POPULATION_TYPE))
       
        // Previous score
        gaugeView.secondaryPercentileEnabled = originalAuditData != nil
        if let prev = originalAuditData {
            gaugeView.secondaryPercentile = prev.actualPercentile(groupType: GROUP_TYPE, populationType: POPULATION_TYPE)
        }
        
        Log.d("Current: \(gaugeView.percentile) (\(lastestAuditData.auditScore))")
        Log.d("Previous: \(gaugeView.secondaryPercentile) (\(originalAuditData?.auditScore ?? -1))")
        
        /////////////////////////////////////////
        // TABLE
        /////////////////////////////////////////
        
        auditHistoryTable.auditHistoryDelegate = self
        auditHistoryTable.auditDataList = allAuditData
    }
    
    //---------------------------------------------------------------------
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        if clearNavStackOnShow {
//            let root = self.navigationController!.viewControllers[0]
//            self.navigationController!.viewControllers = [root, self]
//        }
//    }
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Clear out past VCs if this is a re-audit
//        if sender is PXAuditFeedbackViewController  {
//            clearNavStackOnShow = true
//        }
//    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Event Handlers
    //////////////////////////////////////////////////////////
    
    @IBAction func _whoCompareTriggered(_ sender: Any) {
        let vc = PXWebViewController(resource: "audit-feedback-followup-info")!
        vc.title = "About the Comparison"
        vc.openedOutsideOnboarding = true
        vc.view.backgroundColor = UIColor.white
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissWhoComparePopup))
        self.present(nav, animated: true, completion: nil)
        whoComparesVC = nav
    }
    
    @objc public func dismissWhoComparePopup() {
        whoComparesVC?.dismiss(animated: true, completion: nil)
        whoComparesVC = nil
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Delegate
    //////////////////////////////////////////////////////////

    func userDidSelectAuditData(_ selectedAuditData: AuditData) {
        assert(!VCInjector.shared.isOnboarding) // check we've turned it off or else the VCs involved in the following will do some things we dont intend
        VCInjector.shared.workingAuditData = selectedAuditData
        performSegue(withIdentifier: "ReviewAuditSegue", sender: nil)
    }
    
    //---------------------------------------------------------------------

    
}
