//
//  MakePlanVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 28/02/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import UIKit
import UserNotifications

/**
 @TODO Move UNNotif stuff to a singleton manager (replacing PXLocalNotif...). See README_dev
 */
class MakePlanVC: PXTrackedViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    //////////////////////////////////////////////////////////
    // MARK: - Types & Consts
    //////////////////////////////////////////////////////////
    
//    let REMINDER_DEFAULT_FUTURE:TimeInterval = 1 * 60 * 60 // 1 hour
    let REMINDER_TIME_DEFAULT_HOUR = 17 // default to 5pm
    let REMINDER_MINIMUM_FUTURE:TimeInterval = 1// * 60 // 10 minutes
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////

    //--Public-------------------------------------------------------------
    // @HKS need to check up on this. myplan.reminderTime is set to +000 even in non GMT tz???
    @objc public var currentCalDate: CalendarDate!   // Set internall AND externally by the VC when called
    
    //--IBOutlet-----------------------------------------------------------
    
    @IBOutlet weak var plansColView: UICollectionView!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var reminderTimePicker: UIDatePicker!
    @IBOutlet weak var saveBtn: PXSolidButton!
    @IBOutlet weak var deleteBtn: PXSolidButton!
    @IBOutlet weak var reminderPickerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var plansColViewHConstraint: NSLayoutConstraint!
    @IBOutlet weak var constraintForHidingDeleteBtn: NSLayoutConstraint!
    
    //--Private------------------------------------------------------------

    private var myPlanRec: MyPlanRecord?
    private var systemPlanTemplates:[SystemPlanTemplate] = []
    private var planTemplates:[PlanTemplate] = []
    private var hasLoadedOnce = false
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Your Plan"
        
        plansColView.dataSource = self
        plansColView.delegate = self
        
        deleteBtn.tintColor = UIColor.drinkLessRed()
        
        // Annoying with the AM/PM situation. Just validate on save6
//        reminderTimePicker.addTarget(self, action: Selector("reminderTimePickerChanged"), for: .valueChanged)
//
        // Load the system plan templates and the existing user ones
        systemPlanTemplates = SystemPlanTemplate.loadAll()
        
        // Clear up some bgs
        plansColView.superview!.backgroundColor = UIColor.clear
        plansColView.backgroundColor = UIColor.clear
        reminderSwitch.superview!.backgroundColor = UIColor.clear
        saveBtn.superview!.backgroundColor = UIColor.clear
        
        refreshDataAndView()
        
        screenName = "Make Plan" // for tracking
    }
    
    override func viewWillAppear(_ animated: Bool) {        PXDailyTaskManager.shared().completeTask(withID:"make-plan")

    }
    
    //---------------------------------------------------------------------

    private func refreshDataAndView() {
        Log.d("Refreshing...")
        
        // Data
        planTemplates.removeAll()
        planTemplates.append(contentsOf: systemPlanTemplates)
        try? planTemplates.append(contentsOf: CustomPlanTemplate.loadAll(context: context))
        
        myPlanRec = MyPlanRecord.fetchRecord(for: currentCalDate, context: context)
        
//        // Set time picker to the future
//        let timeRemInDay = (Date().withTruncatedTimeInTimeZone(Calendar.current.timeZone) + 1.days).timeIntervalSince(Date()) - 60 // subtract a min to ensure 11:59pm
//        let pickerAheadTime = REMINDER_DEFAULT_FUTURE > timeRemInDay ? timeRemInDay : REMINDER_DEFAULT_FUTURE
//        reminderTimePicker.date = Date() + pickerAheadTime
  
        // Use day comps from the edit date but with a specific hour
        var dc = currentCalDate.dateComponents
        dc.hour = REMINDER_TIME_DEFAULT_HOUR
        dc.minute = 0
        dc.second = 0
        reminderTimePicker.date = CalendarDate(from:dc).date
        
        let hasExistingRec = self.myPlanRec != nil
        let hasReminder = hasExistingRec && (self.myPlanRec?.reminderTime != nil)
        if hasReminder {
            let calDate = CalendarDate(date: self.myPlanRec!.reminderTime! as Date, timeZoneId: self.myPlanRec!.timezoneStr)
            reminderTimePicker.setDate(calDate.inCurrentTimeZone().date, animated: hasLoadedOnce)
        }
        
        // Plan Templates
        // CollectionView is meant to scroll so we need to do auto-height manually
        let layout = plansColView.collectionViewLayout as! UICollectionViewFlowLayout
        let W = plansColView.frame.size.width
        let cellCnt = planTemplates.count + 1 // (+1 for the custom one)
        let cellW = layout.itemSize.width
        let cellH = layout.itemSize.height
        let hSpacing = layout.minimumInteritemSpacing
        let vSpacing = layout.minimumLineSpacing
        let margins = layout.sectionInset.left + layout.sectionInset.right
        let cellsPerRow:Float = floorf(Float(W - margins)/Float(cellW + hSpacing))
        let rows:Float = ceilf(Float(cellCnt) / cellsPerRow)
        let H = CGFloat(rows) * (cellH + vSpacing) - vSpacing // dont need the spacing on the bottom
        // I think we can just use contentSize.height after the reloadData... ??
        
        // Update animated if not new
        let updateViews = { ()-> Void in
            self.plansColViewHConstraint.constant = H

            self.showHideDeleteBtn(show: hasExistingRec)
            self.deleteBtn.isEnabled = hasExistingRec
            self.showHideReminderTimePicker(show: hasReminder)
        }
        if !hasLoadedOnce {
            updateViews()
        } else {
            UIView.animate(withDuration: 0.25) {
                updateViews()
            }
        }
        
        //plansColView.performBatchUpdates({
            plansColView.reloadData()
        
        // Find the idx
        if let planRec = myPlanRec {
            let selectedTplIdx = planTemplates.firstIndex { (planTpl:PlanTemplate) -> Bool in
                if let tpl = planTpl as? SystemPlanTemplate {
                    if planRec.systemPlanId == tpl.identifier {
                        return true
                    }
                    return false
                } else if let tpl = planTpl as? CustomPlanTemplate {
                    if planRec.customPlan == tpl {
                        return true
                    }
                    return false
                } else {
                    assert(false, "Shoudn't be! (147)")
                }
                return false
            } ?? -1
            // Find the index
            if selectedTplIdx >= 0 {
                // +1 as Write Your Own is first
                plansColView.selectItem(at: IndexPath(item: selectedTplIdx + 1, section: 0), animated: hasLoadedOnce, scrollPosition: .top)
            }
        }
//        }) { (finished:Bool) in
//            // completion
//        }
//
        
        // TODO: refresh reminder time settings
        reminderSwitch.isOn = (myPlanRec != nil) ? (myPlanRec?.reminderTime != nil) : false
        showHideReminderTimePicker(show: reminderSwitch.isOn)
        
        hasLoadedOnce = true
    }
 
    //---------------------------------------------------------------------


    
    //////////////////////////////////////////////////////////
    // MARK: - Widget Events
    //////////////////////////////////////////////////////////

    @IBAction func reminderLabelPressed(_ sender: Any) {
        self.reminderSwitch.isOn = !self.reminderSwitch.isOn
        self.reminderSwitchChanged(self.reminderSwitch)
    }
    
    
    @IBAction func reminderSwitchChanged(_ sender: UISwitch) {
        let toOn = sender.isOn
        let parent = reminderTimePicker.superview!.superview!
        parent.setNeedsLayout()
        UIView.animate(withDuration: 0.25) {
            self.showHideReminderTimePicker(show: toOn)
            parent.layoutIfNeeded()
        }
        
    }
    
    //---------------------------------------------------------------------

//    @objc
//    func reminderTimePickerChanged() {
//        // Validate to future
//        if reminderTimePicker.date.timeIntervalSinceNow < REMINDER_MINIMUM_FUTURE {
//            let d = Date() + REMINDER_MINIMUM_FUTURE
//            reminderTimePicker.setDate(d, animated: true)
//        }
//    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Save / Delete
    //////////////////////////////////////////////////////////

    @IBAction func savePressed(_ sender: Any) {
        Log.d("Save pressed")
        
        // VALIDATE
        if reminderSwitch.isOn &&
            reminderTimePicker.date.timeIntervalSinceNow < REMINDER_MINIMUM_FUTURE {
            UIAlertController.simpleAlert(title: "Error", msg: "Please ensure the Reminder Time is later today.").show(in: self)
            return
        }
        
        guard let selectedIdxPaths = plansColView.indexPathsForSelectedItems, selectedIdxPaths.count > 0 else {
            UIAlertController.simpleAlert(title: "Error", msg: "Please select an plan by tapping the icon").show(in:self)
            return
        }
        
        if myPlanRec == nil {
            myPlanRec = MyPlanRecord.create(in: context)
        }
        
        // REMINDERS
        // Cancel existing if there is one
        if let notifId = myPlanRec!.notificationId {
            self.cancelNotification(notifId: notifId)
            myPlanRec!.notificationId = nil
            Log.d("Cancelling notif id \(notifId)")
        }
        
        // COREDATA
        assert(selectedIdxPaths.count == 1, "Multiple selected plan templates???")
        let idx = plansColView.indexPathsForSelectedItems!.first!.item - 1;  // We've moved Write your Own to the top.
        // System or custom template
        if idx < systemPlanTemplates.count {
            myPlanRec!.systemPlanId = Int16(systemPlanTemplates[idx].identifier)
            myPlanRec!.customPlan = nil // clear out for edit
        } else {
            let customPlanTpl = planTemplates[idx] as! CustomPlanTemplate
            myPlanRec!.customPlan = customPlanTpl
            myPlanRec!.systemPlanId = 0
            
            // set last used in custom template
            customPlanTpl.lastUsed = DateProvider.now
        }
        myPlanRec!.dateGMT = currentCalDate.asGMTCalendarDate().withTruncatedTimeComponents().date as NSDate
        myPlanRec!.timezoneStr = TimeZoneProvider.current.identifier
        
        if !reminderSwitch.isOn {
            myPlanRec!.reminderTime = nil
            
        } else {
            // REMINDER NOTIF
            let reminderTime = reminderTimePicker.date
            let notifId = currentCalDate.withTruncatedTimeComponents().description
            let content = UNMutableNotificationContent()
            content.title = "Remember your plan to..."
            //content.subtitle = ""
            content.body = myPlanRec!.label!
            content.userInfo = ["KEY_LOCALNOTIFICATION_TYPE":"PXMyPlanReminderType"] // for compat with existing system
            content.sound = UNNotificationSound.default
            var dateComps = CalendarProvider.current.dateComponents(in: TimeZoneProvider.current, from: reminderTime)
            dateComps = DateComponents(year: dateComps.year, month: dateComps.month, day: dateComps.day, hour:dateComps.hour, minute:dateComps.minute)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
            let notifReq = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(notifReq) { (e:Error?) in
                if let err = e {
                    Log.e("\(err)")
                    return
                }
                Log.d("Notif Success!")
            }
            Log.d("Set User Notification: \(notifReq)")
            
            myPlanRec!.notificationId = notifId
            myPlanRec!.reminderTime = reminderTime as NSDate
        }
        
        // SAVE n Pop
        try! context.save()
        self.navigationController?.popViewController(animated: true)
        
        // TRACKING / PARSE
        
    }
    
    //---------------------------------------------------------------------

    @IBAction func deletePressed(_ sender: Any) {
        let alert = UIAlertController.confirmationAlert(title: "Delete?", message: "Are you sure you want to delete this plan?") {
            if let notifId = self.myPlanRec!.notificationId {
                self.cancelNotification(notifId: notifId)
            }
            
            self.context.delete(self.myPlanRec!)
            try! self.context.save()
            self.navigationController?.popViewController(animated: true)
        }
        alert.show(in: self)
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - DataSource
    //////////////////////////////////////////////////////////
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return planTemplates.count + 1  // +1 for "write your own"
    }
    
    //---------------------------------------------------------------------
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlanCell", for: indexPath) as! PlanCell
        
        var idx = indexPath.item
        
        if idx == 0 {
            // Write your own...
            cell.label!.text = "Write your own..."
            cell.iconImgV?.image = UIImage(named: "plan-write")
        } else {
            // Existing
            idx -= 1  // 0 is write your own, so shift hem back
            let planTpl = planTemplates[idx]
            cell.label!.text = planTpl.label
            cell.iconImgV!.image = UIImage(named: planTpl.icon)
        }
        return cell
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Delegates
    //////////////////////////////////////////////////////////

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let idx = indexPath.item
        if idx == 0 {
            promptForAndCreateCustomPlan()
        }
    }
    
    private func promptForAndCreateCustomPlan() {
        let msg = "Enter a short description for your plan (e.g. Go to the park)"
        let alert = UIAlertController.textPromptAlert(title: nil, message: msg) { (inputText:String?) in
            if let labelTxt = inputText {
                self.addCustomPlanTemplate(label: labelTxt)
            } else {
                self.promptForAndCreateCustomPlan()
            }
        }
        
        alert.show(in: self)
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    // Sets the layout params to show hide the time wheel (non animated)
    private func showHideReminderTimePicker(show:Bool) {
        let pickerH = reminderTimePicker.frame.size.height
        self.reminderPickerBottomConstraint.constant = show ? 0 : -pickerH
        
    }
    
    //---------------------------------------------------------------------

    private func addCustomPlanTemplate(label:String) {
        let plan = CustomPlanTemplate.create(in: self.context)
        plan.label = label
        plan.icon = "plan-write"  // fixed for now
        try! self.context.save()
        
        plansColView.performBatchUpdates({
            refreshDataAndView()
            // animate it in
            let newIdx = planTemplates.firstIndex(where: { (tpl: PlanTemplate) -> Bool in
                return tpl.label == label
            })!
            
            plansColView.insertItems(at: [IndexPath(item: newIdx + 1, section: 0)]) // +1 is for the Write Your Own icon
        }, completion: nil)
        
    }
    
    //---------------------------------------------------------------------

    private func showHideDeleteBtn(show:Bool) {
        self.constraintForHidingDeleteBtn.constant = show ? 83 : 20
    }

    //---------------------------------------------------------------------

    private func cancelNotification(notifId:String) {
        Log.d("Removing reminder notification with id: \(notifId)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifId])
    }
    
}
