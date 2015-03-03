//
//  TreinTicker+WatchHelper.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 02-03-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

extension TreinTicker {
  func bumpFrom() {
    
    if closeStations.count == 0 {
      return;
    }
    
    let index = findIndex(closeStations, from!)
    
    if let i = index {
      println("index \(i), \((i+1)), \(closeStations.count), \((closeStations.count - 1) > i)")
      if (closeStations.count - 1) > i {
        from = closeStations[(i+1)]
      } else {
        from = closeStations.first
      }
    } else {
      from = closeStations.first
    }
  }
}
