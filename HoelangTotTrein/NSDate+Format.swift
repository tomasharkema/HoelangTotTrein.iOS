//
//  NSDate+Format.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct HHMMSS {
  var hour:String?
  var minute:String
  var second:String
  var date:NSDate
  
  func string() -> String {
    var h:String = ""
    if let hu = hour {
      h = hu + ":"
    }
    
    return "\(h)\(minute):\(second)"
  }
}

struct HHMM {
  var hour:String
  var minute:String
  var date:NSDate
  
  func string() -> String {
    return "\(hour):\(minute)"
  }
}

extension NSDate {
  
  func toMMSSFromNow() -> HHMMSS {
    
    var flags: NSCalendarUnit = .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
    var options: NSCalendarOptions = .WrapComponents
    
    let com = NSCalendar.currentCalendar().components(flags, fromDate: NSDate(), toDate: self, options: options)
    
    let hour:String? = com.hour > 0 ? "\(com.hour)" : .None
    let minute = com.minute < 10 ? String("0\(com.minute)") : String(com.minute)
    let second = com.second < 10 ? String("0\(com.second)") : String(com.second)
    
    return HHMMSS(hour: hour, minute: minute, second: second, date:self)
  }
  
  func toHHMM() -> HHMM {
    var flags: NSCalendarUnit = .HourCalendarUnit | .MinuteCalendarUnit
    
    let com = NSCalendar.currentCalendar().components(flags, fromDate: self)
    
    let hour = com.hour < 10 ? String("0\(com.hour)") : String(com.hour)
    let minute = com.minute < 10 ? String("0\(com.minute)") : String(com.minute)
    
    return HHMM(hour: hour, minute: minute, date:self)
  }
  
}