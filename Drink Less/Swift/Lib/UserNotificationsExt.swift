//
//  UserNotificationsExt.swift
//  drinkless
//
//  Created by Hari Karam Singh on 10/09/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import Foundation
import UserNotifications


extension UNUserNotificationCenter {
    
    // A timezone independent easy scheduler
    public func scheduleLocalNotification(identifier:String, title: String? = nil, body: String? = nil, userInfo: [String: Any]? = nil, dateComps:DateComponents, repeats:Bool = false, callback:((Error?) -> Void)? = nil) {
        
        let content = UNMutableNotificationContent()
        if let t = title {
            content.title = t
        }
        //content.subtitle = ""
        if let b = body {
            content.body = b
        }
        if let uinf = userInfo {
            content.userInfo = uinf
        }
        content.sound = UNNotificationSound.default
    
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: repeats)
        let notifReq = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(notifReq, withCompletionHandler: callback)
    }
    
    
}
