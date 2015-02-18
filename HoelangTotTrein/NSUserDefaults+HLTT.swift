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

extension NSUserDefaults {
  
  var stations:[Station] {
    get {
      if let data = objectForKey(StationsKey) as? NSData {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as [Station]
      }
      return []
    }
    set {
      setObject(NSKeyedArchiver.archivedDataWithRootObject(newValue), forKey: StationsKey)
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
    }
  }
  
  var from:String {
    set {
      setValue(newValue, forKey: FromKey)
    }
    get {
      return objectForKey(FromKey) as? String ?? ""
    }
  }
  
  var to:String {
    set {
      setValue(newValue, forKey: ToKey)
    }
    get {
      return objectForKey(ToKey) as? String ?? ""
    }
  }
  
  var originalFrom:String {
    set {
      setValue(newValue, forKey: OriginalFromKey)
    }
    get {
      return objectForKey(OriginalFromKey) as? String ?? ""
    }
  }
}
