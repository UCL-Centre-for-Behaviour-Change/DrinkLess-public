//
//  MyPlanRecord+CoreDataClass.swift
//  
//
//  Created by Hari Karam Singh on 27/02/2019.
//
//

import Foundation
import CoreData

@objc(MyPlanRecord)
public class MyPlanRecord: NSManagedObject, TimeZonedModelAbstract {
    
    //////////////////////////////////////////////////////////
    // MARK: - Class methods
    //////////////////////////////////////////////////////////
    
    @objc public class func fetchRecord(for calendarDate:CalendarDate, context:NSManagedObjectContext) -> MyPlanRecord? {
        // Convert to GMT dates
        let from = calendarDate.asGMTCalendarDate().withTruncatedTimeComponents()
        let to = from + 1.days
        
        let fr:NSFetchRequest<MyPlanRecord> = self.fetchRequest()
        let pred = NSPredicate(format: "dateGMT >= %@ AND dateGMT < %@", from.date as NSDate, to.date as NSDate)
        fr.predicate = pred
        
        var recs = try! context.fetch(fr);
        if recs.count > 1 {
            Log.w("More than one MyPlan record for calendar date \(calendarDate)")
        } else if recs.count == 0 {
            return nil
        }
        return recs[0]
        
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    @objc public var label : String? {
        if let plan = customPlan {
            return plan.label
        } else if let plan = SystemPlanTemplate(id: systemPlanId) {
            // TODO: Query system plan
            return plan.label
        }
        return nil
    }
    
    @objc public var iconName : String? {
        var imgName:String? = nil
        if let plan = customPlan {
            imgName = plan.icon
        } else if let plan = SystemPlanTemplate(id: systemPlanId) {
            imgName = plan.icon
        }
        return imgName
    }
    
    @objc public var iconImg : UIImage? {
        let imgName = iconName
        return (imgName != nil) ? UIImage(named:imgName!) : nil
    }

    
    //////////////////////////////////////////////////////////
    // MARK: - Public Methods
    //////////////////////////////////////////////////////////

    @objc override public func didSave() {
        Log.d("Saving to Parse...")
        
        var actionName = "CREATE"
        if isDeleted {
            actionName = "DELETE"
        } else if !isInserted {
            actionName = "UPDATE"
        }
        
        // Convert reminder date to a time format
        var reminderTimeStr = ""
        if let remindTime = reminderTime as Date? {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            let tz = TimeZone(identifier:timezoneStr)!
            df.timeZone = tz
            reminderTimeStr = df.string(from: remindTime)
        }
        
        let params:[String:Any] = [
            "action":actionName,
            "calendarDateGMT":dateGMT,
            "hasReminder":notificationId != nil,
            "reminderTime":reminderTimeStr,
            "timeZone":timezoneStr,
            "planLabel":label ?? "",
            "planIcon":iconName ?? "",
            "isCustom":customPlan != nil
        ]
        self.server.saveDataObject(className: String(describing: type(of:self)), objectId: nil, isUser: true, params: params, ensureSave: false, callback: nil)
    }
}
