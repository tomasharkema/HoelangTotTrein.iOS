//
//  Array+HLTT.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 18-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

extension Array {
  
  func slice(n:Int) -> [T] {
    
    if n == -1 {
      return self
    }
    
    var objects: [T] = []
    var index = 0
    
    for obj in self {
      if index == n {
        return objects
      } else {
        objects.append(obj)
        index++
      }
    }
    
    return objects
  }
  
  func contains<T : Equatable>(obj: T) -> Bool {
    return self.filter({$0 as? T == obj}).count > 0
  }
  
}