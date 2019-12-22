//
//  Log.swift
//  drinkless
//
//  Created by Hari Karam Singh on 10/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation


class Log {
    static var debugEnabled = Debug.ENABLED
    static var verboseEnabled = Debug.LOG_VERBOSE
    
    private class func log(_ msg:String, filename:String, line:Int, suffix:String = "") {
        let s = filename.split(separator: ".");
        let noExt = s.dropLast().joined(separator: ".")
        var file = String(noExt.split(separator: "/").last!)
        file = file.uppercased()
        var prefix = "\(file):\(line)"
        if suffix.count > 0 {
            prefix += ":\(suffix)"
        }
        print("[\(prefix)] \(msg)")
    }
    
    class func i(_ msg:String, filename:String = #file, line:Int=#line) {
        Log.log(msg, filename:filename, line:line)
    }
    class func w(_ msg:String, filename:String = #file, line:Int=#line) {
        Log.log(msg, filename:filename, line:line, suffix: "WARNING")
    }
    class func e(_ msg:String, filename:String = #file, line:Int=#line) {
        Log.log(msg, filename:filename, line:line, suffix: "ERROR")
    }
    class func d(_ msg:String, filename:String = #file, line:Int=#line) {
        if !debugEnabled {return}
        Log.log(msg, filename:filename, line:line, suffix: "DEBUG")
    }
    class func v(_ msg:String, filename:String = #file, line:Int=#line) {
        if !verboseEnabled {return}
        Log.log(msg, filename:filename, line:line, suffix: "VERBOSE")
    }
}
