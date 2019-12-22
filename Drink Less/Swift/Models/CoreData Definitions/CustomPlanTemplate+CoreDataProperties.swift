//
//  CustomPlanTemplate+CoreDataProperties.swift
//  
//
//  Created by Hari Karam Singh on 28/02/2019.
//
//

import Foundation
import CoreData


extension CustomPlanTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomPlanTemplate> {
        return NSFetchRequest<CustomPlanTemplate>(entityName: "CustomPlanTemplate")
    }

    @NSManaged public var label: String
    @NSManaged public var icon: String
    @NSManaged public var lastUsed: Date

}
