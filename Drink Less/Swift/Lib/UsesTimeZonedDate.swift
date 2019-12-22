//
//  HasCalendarDate.swift
//  drinkless
//
//  Created by Hari Karam Singh on 08/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation


/** This was all used for the AuditData work. For the Behav Subst stuff we are starting from first principles and using GMT dates in the DB. So consider this stuff deprecated and not related to CalendarDate (which is the new method) */

protocol UsesTimeZonedDate {
    var date:NSDate? { get }
    var timezone:String? { get }
}


extension UsesTimeZonedDate {
    func hasEarlierCalendarDateThan(obj:UsesTimeZonedDate) -> Bool {
        let d1 = self
        let d2 = obj
        let tz1 = NSTimeZone(name: d1.timezone!)!
        let tz2 = NSTimeZone(name: d2.timezone!)!
        let date1 = d1.date?.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: tz1 as TimeZone)
        let date2 = d2.date?.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: tz2 as TimeZone)
        return date1!.compare(date2!) == ComparisonResult.orderedAscending
    }
}






//
//func  > <T:UsesTimeZonedDate>(d1:T, d2:T) -> Bool {
//    let tz1 = NSTimeZone(name: d1.timezone!)!
//    let tz2 = NSTimeZone(name: d2.timezone!)!
//    let date1 = d1.date?.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: tz1 as TimeZone)
//    let date2 = d2.date?.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: tz2 as TimeZone)
//    return date1!.compare(date2!) == ComparisonResult.orderedDescending
//}
//func  < <T:UsesTimeZonedDate>(d1:T, d2:T) -> Bool {
//    let tz1 = NSTimeZone(name: d1.timezone!)!
//    let tz2 = NSTimeZone(name: d2.timezone!)!
//    let date1 = d1.date?.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: tz1 as TimeZone)
//    let date2 = d2.date?.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: tz2 as TimeZone)
//    return date1!.compare(date2!) == ComparisonResult.orderedAscending
//}
//
//func  == <T:UsesTimeZonedDate>(d1:T, d2:T) -> Bool {
//    return !(d1 < d2) && !(d2 < d1)
//}
//func  >= <T:UsesTimeZonedDate>(d1:T, d2:T) -> Bool {
//    return (d1 > d2) || (d1 == d2)
//}
//func  <= <T:UsesTimeZonedDate>(d1:T, d2:T) -> Bool {
//    return (d1 < d2) || (d1 == d2)
//}

