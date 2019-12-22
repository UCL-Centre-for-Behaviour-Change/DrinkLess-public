//
//  MyPlanRecord+CoreDataProperties.swift
//  
//
//  Created by Hari Karam Singh on 28/02/2019.
//
//

import Foundation
import CoreData


extension MyPlanRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyPlanRecord> {
        return NSFetchRequest<MyPlanRecord>(entityName: "MyPlanRecord")
    }

    @NSManaged public var dateGMT: NSDate  // GMT date with same calendar date as the one at the time of save in specified timezone (see readme)
    @NSManaged public var reminderTime: NSDate?  // The literal one in the specified timezone
    @NSManaged public var timezoneStr: String
    @NSManaged public var systemPlanId: Int16
    @NSManaged public var notificationId: String?
    @NSManaged public var customPlan: CustomPlanTemplate?

}
