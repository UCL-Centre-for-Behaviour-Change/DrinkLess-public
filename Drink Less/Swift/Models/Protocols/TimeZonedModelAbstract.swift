//
//  CalendarDateModelAbstract.swift
//  drinkless
//
//  Created by Hari Karam Singh on 27/02/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import Foundation

protocol TimeZonedModelAbstract {
    var timezoneStr: String {get set}
}


extension TimeZonedModelAbstract {
    var timeZone: TimeZone? {
        return TimeZone(identifier: timezoneStr)
    }
    
}
