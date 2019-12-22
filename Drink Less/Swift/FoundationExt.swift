//
//  CocoaExt.swift
//  drinkless
//
//  Created by Hari Karam Singh on 15/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation


//////////////////////////////////////////////////////////
// MARK: - NSBundle
//////////////////////////////////////////////////////////

extension Bundle {
}


extension Date {
//    /** Creates a date in UTC time with the same components as the current one  */
//    func asGMTDateMatchingComponentsToThisCalendar(_ calendar: Calendar) -> Date {
//
//        var dateComps: DateComponents = calendar.dateComponents(in: calendar.timeZone, from: self)
//
//        var gmtCal = Calendar.current
//        gmtCal.timeZone = TimeZone(abbreviation: "GMT")!
//        dateComps.calendar = gmtCal
//        dateComps.timeZone = gmtCal.timeZone //jic
//        let newDate = dateComps.date!
//        return newDate
//    }
//
    func withSameComponentsInNewTimeZone(thisDatesTimeZone:TimeZone, newTimeZone: TimeZone) -> Date {
        var cal = CalendarProvider.current
        cal.timeZone = newTimeZone
        var dateComps: DateComponents = cal.dateComponents(in: newTimeZone, from: self)
        dateComps.calendar = cal
        dateComps.timeZone = cal.timeZone //jic
        let newDate = dateComps.date!
        return newDate
    }
    
    //---------------------------------------------------------------------
    
//    /** The old obj-c method is called strictDateFromToday */
    func withTruncatedTimeInTimeZone(_ timeZone: TimeZone) -> Date {
        var cal = CalendarProvider.current
        cal.timeZone = timeZone
        var dateComps: DateComponents = cal.dateComponents(in: timeZone, from: self)
        dateComps.hour = 0
        dateComps.minute = 0;
        dateComps.second = 0;
        dateComps.nanosecond = 0;
        dateComps.calendar = cal
        dateComps.timeZone = cal.timeZone //jic
        let newDate = dateComps.date!
        return newDate
    }
}


extension Int {
    // 1.day in TimeInteral (seconds float)
    var days: TimeInterval {
        return TimeInterval(self * 3600 * 24)
    }
    var hours: TimeInterval {
        return TimeInterval(self * 3600)
    }
    var minutes: TimeInterval {
        return TimeInterval(self * 60)
    }
    var seconds: TimeInterval {
        return TimeInterval(self)
    }
}

//---------------------------------------------------------------------

/** Not working for some reason */
extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

