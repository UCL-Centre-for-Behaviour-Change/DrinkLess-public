//
//  DateTimeDebug.swift
//  drinkless
//
//  Created by Hari Karam Singh on 06/04/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import Foundation

public final class CalendarProvider {
    public static var current: Calendar {
        var cal = Calendar.current
        if Debug.ENABLED && Debug.ENABLE_TIME_PANEL {
            cal.timeZone = TimeZoneProvider.current
        }
        return cal
    }
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

public final class DateProvider {
    public static var now:Date {
        if Debug.ENABLED && Debug.ENABLE_TIME_PANEL {
            let hoursShift = DLDebugger.sharedInstance().timeHoursShift
            let d = Date() + TimeInterval(hoursShift * 3600)
            return d
        }
        return Date()
    }
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

public final class TimeZoneProvider {
    public static var current:TimeZone {
        if Debug.ENABLED && Debug.ENABLE_TIME_PANEL {
            if let tzName = DLDebugger.sharedInstance().timeZoneName {
                if let tz = TimeZone(identifier: tzName) {
                    return tz
                }
            }
        }
        return Calendar.current.timeZone
    }
    
    // I dont think we need to mock out the initialisers that take dates
}
