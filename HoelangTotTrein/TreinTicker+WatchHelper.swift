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
      if (closeStations.count - 1) > i {
        from = closeStations[(i+1)]
      } else {
        from = closeStations.first
      }
    } else {
      from = closeStations.first
    }
  }
  
  func bumpTo() {
    let mostUsed = MostUsed.getListByVisited().slice(10).filter {
      return $0.code != self.from.code
    }
    
    if mostUsed.count == 0 {
      return;
    }
    
    let index = findIndex(mostUsed, to!)
    
    if let i = index {
      if (mostUsed.count - 1) > i {
        to = mostUsed[(i+1)]
      } else {
        to = mostUsed.first
      }
    } else {
      to = mostUsed.first
    }
  }
  
}
