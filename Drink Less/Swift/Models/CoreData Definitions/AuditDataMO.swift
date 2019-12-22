//
//  AuditDataMO.swift
//  drinkless
//
//  Created by Hari Karam Singh on 01/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit
import CoreData

@objc(AuditDataMO)
class AuditDataMO: NSManagedObject, UsesTimeZonedDate {
    
    @NSManaged public var countryActual: NSNumber?
    @NSManaged public var countryDrinkersActual: NSNumber?
    @NSManaged public var demographicActual: NSNumber?
    @NSManaged public var demographicDrinkersActual: NSNumber?
    @NSManaged public var auditAnswers: Any?
    @NSManaged public var auditScore: NSNumber?
    @NSManaged public var auditCScore: NSNumber?  // 3 question tally
    @NSManaged public var date: NSDate?
    @NSManaged public var timezone: String?
    @NSManaged public var demographic: String?
    @NSManaged public var countryEstimate: NSNumber?
    @NSManaged public var demographicEstimate: NSNumber?
    
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuditDataMO> {
//        return NSFetchRequest<AuditDataMO>(entityName: "AuditDataMO")
//    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    class func latest(in context:NSManagedObjectContext) -> AuditDataMO? {
        let req = NSFetchRequest<AuditDataMO>(entityName: "AuditDataMO")
        req.fetchLimit = 5
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let obj = (try? context.fetch(req))?.first
        return obj
    }
    
    //---------------------------------------------------------------------

    class func first(in context:NSManagedObjectContext) -> AuditDataMO? {
        let req = NSFetchRequest<AuditDataMO>(entityName: "AuditDataMO")
        req.fetchLimit = 1
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let obj = (try? context.fetch(req))?.first
        return obj
    }
    
    //---------------------------------------------------------------------

    class func all(in context:NSManagedObjectContext) -> [AuditDataMO]? {
        let req = NSFetchRequest<AuditDataMO>(entityName: "AuditDataMO")
        
        guard let records = try? context.fetch(req) else {
            return nil
        }
        
        return records
    }
    
    //---------------------------------------------------------------------

    convenience init(context:NSManagedObjectContext) {
        let name = NSStringFromClass(type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }
    
    
    
}
