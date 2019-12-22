//
//  AuditHistoryTableView.swift
//  drinkless
//
//  Created by Hari Karam Singh on 08/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

protocol AuditHistoryTableViewDelegate {
    func userDidSelectAuditData(_ selectedAuditData:AuditData)
}


class AuditHistoryTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    var auditHistoryDelegate: AuditHistoryTableViewDelegate?
    
    /////////c/////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    var auditDataList:[AuditData]? {
        didSet {
            self.reloadData()
        }
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    required override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    private func setup() {
        delegate = self
        dataSource = self
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Delegate, Datasource
    //////////////////////////////////////////////////////////

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return auditDataList?.count ?? 0
    }
    
    //---------------------------------------------------------------------

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //---------------------------------------------------------------------

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Drinking Review History"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AuditEntryCell")!
        let label = cell.viewWithTag(101) as! UILabel
        label.text = "Problem. Please contact support."
        if let entry = auditDataList?[indexPath.row] {
            let df = DateFormatter()
            let date = entry.date!.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: entry.timezone)!
            df.dateStyle = .long
            df.timeStyle = .none
            label.text = df.string(from: date)
        }
        return cell
    }
    
    //---------------------------------------------------------------------

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Callback
        auditHistoryDelegate?.userDidSelectAuditData(auditDataList![indexPath.row])
        
    }
}
