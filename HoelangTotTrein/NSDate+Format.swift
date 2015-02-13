//
//  NSDate+Format.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct MMSS {
    var minute:String
    var second:String
}

extension NSDate {
    
    func toMMSS() -> MMSS {
        
        var flags: NSCalendarUnit = .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
        var options: NSCalendarOptions = .WrapComponents
        
        let com = NSCalendar.currentCalendar().components(flags, fromDate: NSDate(), toDate: self, options: options)
        
        let minute = com.minute < 10 ? String("0\(com.minute)") : String(com.minute)
        let second = com.second < 10 ? String("0\(com.second)") : String(com.second)
        
        return MMSS(minute: minute, second: second)
    }
    
}