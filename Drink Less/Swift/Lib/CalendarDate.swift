//
//  CalendarDate.swift
//  drinkless
//
//  Created by Hari Karam Singh on 27/02/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import Foundation

/** In some sense DateComponents is a better representative of this but I feel it's confusing so I'm creating this. Basically it's a date/tz combo that performs comparisons and conversions where the date _components_ are primary. Are terminology for this is CalendarDate. Also, only Y-M-D is considered. H:M:S are trncated to 0 (ie midnight) */
@objc
public class CalendarDate: NSObject {
    
    @objc public var date:Date
    @objc public var timeZone:TimeZone
    
    //////////////////////////////////////////////////////////
    // MARK: - Operators
    //////////////////////////////////////////////////////////
    
    static func + (lhs: CalendarDate, rhs:TimeInterval) -> CalendarDate {
        return CalendarDate(date: lhs.date + rhs, timeZone: lhs.timeZone)
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    // Current cal date in Current time zone
    @objc override required init() {
        timeZone = TimeZoneProvider.current
        date = DateProvider.now // Date() //.dateWithTruncatedTimeInTimeZone(timeZone)
        // Issue with our debug panel. Date() seems to use the system time zone which is either NSTimeZone.systemTimeZone or the autoupdatingCurrent above ??
        super.init()
    }
    
    //---------------------------------------------------------------------
    
    @objc convenience init(date:Date, timeZone:TimeZone = TimeZoneProvider.current) {
        self.init()
        self.date = date //.dateWithTruncatedTimeInTimeZone(timeZone)
        self.timeZone = timeZone
    }
    
    @objc convenience init(date:Date, timeZoneId:String) {
        self.init()
        self.date = date //.dateWithTruncatedTimeInTimeZone(timeZone)
        self.timeZone = TimeZone(identifier: timeZoneId)!
    }
    
    @objc convenience init(withGMTDate date:Date) {
        let tz = TimeZone(abbreviation: "GMT")!
        self.init(date: date, timeZone: tz)
    }
    
    @objc convenience init(from dateComponents:DateComponents) {
        self.init()
        timeZone = dateComponents.timeZone!
        date = dateComponents.date!
    }
    
    //---------------------------------------------------------------------
    
    public override var description: String {
        let df = DateFormatter()
        df.dateFormat = "EEE d MMM HH:mm:ss"
        var cal = CalendarProvider.current
        cal.timeZone = timeZone
        df.calendar = cal
        return df.string(from: date)
    }
    
    public override var debugDescription: String {
        return "<CalendarDate: \(self.description) \(self.timeZone)>"
    }
    
    

    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////

    @objc public var isGMT:Bool {
        return timeZone.abbreviation() == "GMT"
    }

    @objc public var calendar:Calendar {
        var cal = CalendarProvider.current
        cal.timeZone = timeZone
        return cal
    }
    
    @objc public var dateComponents:DateComponents {
        return CalendarProvider.current.dateComponents(in: timeZone, from: date)
    }

    //////////////////////////////////////////////////////////
    // MARK: - Public Methods
    //////////////////////////////////////////////////////////
    
    @objc
    public func compare(_ to: CalendarDate) -> ComparisonResult {
        // Normalise
        let selfGMT = self.asGMTCalendarDate().date
        let compareGMT = to.asGMTCalendarDate().date
     
        if (selfGMT == compareGMT) {
            return ComparisonResult.orderedSame
        } else if (selfGMT > compareGMT) {
            return ComparisonResult.orderedDescending
        } else {
            return ComparisonResult.orderedAscending
        }
    }
    
    @objc public func asGMTCalendarDate() -> CalendarDate {
        let gmtTZ = TimeZone(abbreviation: "GMT")!

        let gmtDate = self.date.withSameComponentsInNewTimeZone(thisDatesTimeZone: timeZone, newTimeZone: gmtTZ)

        return CalendarDate(date: gmtDate, timeZone: gmtTZ)
    }
    
    //---------------------------------------------------------------------

    /** Has the same components just in the new time zone */
    @objc public func inNewTimeZone(_ newTimeZone: TimeZone) -> CalendarDate {
        let newDate = date.withSameComponentsInNewTimeZone(thisDatesTimeZone: timeZone, newTimeZone: newTimeZone)
        let cd = CalendarDate(date: newDate, timeZone: newTimeZone)
        return cd
    }
    
    //---------------------------------------------------------------------
    
    /** Has the same components just in the new time zone */
    @objc public func inCurrentTimeZone() -> CalendarDate {
        let tz = TimeZoneProvider.current
        let newDate = date.withSameComponentsInNewTimeZone(thisDatesTimeZone: timeZone, newTimeZone: tz)
        let cd = CalendarDate(date: newDate, timeZone: tz)
        return cd
    }
    
    //---------------------------------------------------------------------
    
    // Sets it to 00:00:00 time in the current timezone
    @objc public func withTruncatedTimeComponents() -> CalendarDate {
        let newDate = date.withTruncatedTimeInTimeZone(timeZone)
        return CalendarDate(date: newDate, timeZone: timeZone)
    }
}
