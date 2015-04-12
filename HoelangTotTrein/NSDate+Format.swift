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
    
    let h = max(com.hour, 0)
    let m = max(com.minute, 0)
    let s = max(com.second, 0)
    
    let hour:String? = h > 0 ? "\(h)" : .None
    let minute = m < 10 ? String("0\(m)") : String(m)
    let second = s < 10 ? String("0\(s)") : String(s)
    
    return HHMMSS(hour: hour, minute: minute, second: second, date:self)
  }
  
  func toHHMM() -> HHMM {
    var flags: NSCalendarUnit = .HourCalendarUnit | .MinuteCalendarUnit
    
    let com = NSCalendar.currentCalendar().components(flags, fromDate: self)
    
    let h = max(com.hour, 0)
    let m = max(com.minute, 0)
    
    let hour = h < 10 ? String("0\(h)") : String(h)
    let minute = m < 10 ? String("0\(m)") : String(m)
    
    return HHMM(hour: hour, minute: minute, date:self)
  }
  
  func toHMSSFromNow() -> HHMMSS {
    var flags: NSCalendarUnit = .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit
    var options: NSCalendarOptions = .WrapComponents
    
    let com = NSCalendar.currentCalendar().components(flags, fromDate: NSDate(), toDate: self, options: options)
    
    let h = max(com.hour, 0)
    let m = max(com.minute, 0)
    let s = max(com.second, 0)
    
    let hour:String? = h > 0 ? "\(h)" : .None
    let minute = String(m)
    let second = s < 10 ? String("0\(s)") : String(s)
    
    return HHMMSS(hour: hour, minute: minute, second: second, date:self)
  }
  
}