//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 18-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

let StationsKey = "StationKeys"
let MostUsedKey = "MostUsedAndDateKey"
let FromKey = "FromKey"
let ToKey = "ToKey"
let OriginalFromKey = "OriginalFromKey"
let CurrentAdvice = "CurrentAdvice"
let Advices = "Advices"
let AdviceOffset = "AdviceOffset"
let LastOpenedKey = "LastOpenedKey"

let UserDefaults = NSUserDefaults(suiteName: "group.tomas.hltt")!
let CloudUserService = NSUbiquitousKeyValueStore.defaultStore()

extension NSUserDefaults {
  
  var stations:[Station] {
    set {
      self.setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: StationsKey)
    }
    get {
      NSKeyedUnarchiver.setClass(Station.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein.Station")
      NSKeyedUnarchiver.setClass(Station.classForKeyedUnarchiver(), forClassName: "Widget.Station")
      NSKeyedUnarchiver.setClass(Station.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein_WatchKit_Extension.Station")
      if let data = objectForKey(StationsKey) as? NSData {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as [Station]
      }
      return []
    }
  }
  
  var mostUsed:[[NSString:AnyObject]] {
    get {
      if let mostUsedArray = arrayForKey(MostUsedKey) {
        return mostUsedArray as [[NSString:AnyObject]]
      } else {
        return []
      }
    }
    set {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        self.setObject(newValue, forKey: MostUsedKey)
        
        CloudUserService.setArray(newValue, forKey: MostUsedKey)
      }
    }
  }
  
  var from:String {
    set {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        self.setValue(newValue, forKey: FromKey)
        
        CloudUserService.setString(newValue, forKey: FromKey)
      }
    }
    get {
      return objectForKey(FromKey) as? String ?? ""
    }
  }
  
  var to:String {
    set {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        self.setValue(newValue, forKey: ToKey)
        
        CloudUserService.setString(newValue, forKey: ToKey)
      }
    }
    get {
      return objectForKey(ToKey) as? String ?? ""
    }
  }
  
  var originalFrom:String {
    set {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        self.setValue(newValue, forKey: OriginalFromKey)
      }
    }
    get {
      return objectForKey(OriginalFromKey) as? String ?? ""
    }
  }
  
  var advices:[Advice] {
    set {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        self.setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: Advices)
      }
    }
    get {
      NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein.Advice")
      NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "Widget.Advice")
      NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein_WatchKit_Extension.Advice")
      if let data = objectForKey(Advices) as? NSData {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Advice] ?? []
      }
      return []
    }
  }
  
  var currentAdvice:Advice? {
    set {
      if let advice = newValue {
        self.setObject(NSKeyedArchiver.archivedDataWithRootObject(advice), forKey: CurrentAdvice)
        return;
      }
    }
    get {
      NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein.Advice")
      NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "Widget.Advice")
      NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein_WatchKit_Extension.Advice")
      if let data = objectForKey(CurrentAdvice) as? NSData {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Advice
      }
      return nil
    }
  }
  
  var adviceOffset:NSDate? {
    get {
      let double = doubleForKey(AdviceOffset)
      if double == 0 {
        return nil
      } else {
        return NSDate(timeIntervalSince1970:double)
      }
    }
    set {
      self.setDouble(newValue?.timeIntervalSince1970 ?? 0, forKey: AdviceOffset)
    
      CloudUserService.setDouble(newValue!.timeIntervalSince1970, forKey: AdviceOffset)
    }
  }
  
  var lastOpened:NSDate {
    get {
      return NSDate(timeIntervalSince1970: doubleForKey(LastOpenedKey))
    }
    set {
      setDouble(newValue.timeIntervalSince1970, forKey: LastOpenedKey)
    }
  }
  
}
