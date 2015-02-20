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

let UserDefaults = NSUserDefaults(suiteName: "group.tomas.hltt")!

extension NSUserDefaults {
  
  var stations:[Station] {
    set {
      setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: StationsKey)
      synchronize()
    }
    get {
      if let data = objectForKey(StationsKey) as? NSData {
        NSKeyedUnarchiver.setClass(Station.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein.Station")
        NSKeyedUnarchiver.setClass(Station.classForKeyedUnarchiver(), forClassName: "Widget.Station")
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
  
  var currentAdvice:Advice? {
    set {
      setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue!), forKey: CurrentAdvice)
      synchronize()
    }
    get {
      if let data = objectForKey(CurrentAdvice) as? NSData {
        NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "HoelangTotTrein.Advice")
        NSKeyedUnarchiver.setClass(Advice.classForKeyedUnarchiver(), forClassName: "Widget.Advice")
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Advice
      }
      return nil
    }
  }
}
