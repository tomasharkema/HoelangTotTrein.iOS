//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 18-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

let StationsKey = "StationKeys"
let MostUsedKey = "MostUsedKey"
let FromKey = "FromKey"
let ToKey = "ToKey"
let OriginalFromKey = "OriginalFromKey"
let CurrentAdvice = "CurrentAdvice"
let Advices = "Advices"
let AdviceOffset = "AdviceOffset"

let UserDefaults = NSUserDefaults(suiteName: "group.tomas.hltt")!

extension NSUserDefaults {
  
  var stations:[Station] {
    set {
      setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: StationsKey)
      synchronize()
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
  
  var mostUsed:[NSString] {
    get {
      if let mostUsedArray = arrayForKey(MostUsedKey) {
        return mostUsedArray as [NSString]
      } else {
        return []
      }
    }
    set {
      setObject(newValue, forKey: MostUsedKey)
      synchronize()
    }
  }
  
  var from:String {
    set {
      setValue(newValue, forKey: FromKey)
      synchronize()
    }
    get {
      return objectForKey(FromKey) as? String ?? ""
    }
  }
  
  var to:String {
    set {
      setValue(newValue, forKey: ToKey)
      synchronize()
    }
    get {
      return objectForKey(ToKey) as? String ?? ""
    }
  }
  
  var originalFrom:String {
    set {
      setValue(newValue, forKey: OriginalFromKey)
      synchronize()
    }
    get {
      return objectForKey(OriginalFromKey) as? String ?? ""
    }
  }
  
  var advices:[Advice] {
    set {
      setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: Advices)
      synchronize()
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
        setObject(NSKeyedArchiver.archivedDataWithRootObject(advice), forKey: CurrentAdvice)
        synchronize()
        return;
      }
      println("currentAdvice PROBLEMEN")
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
      if newValue == nil {
        println("adviceOffset has been set nil")
      }
      setDouble(newValue?.timeIntervalSince1970 ?? 0, forKey: AdviceOffset)
      synchronize()
    }
  }
  
}
