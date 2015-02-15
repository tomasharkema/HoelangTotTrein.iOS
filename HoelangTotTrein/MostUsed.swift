//
//  MostUsed.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 15-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

let MOSTUSEDKEY:String = "MostUsedKeyBla"

class StationUsed {
    let station:Station
    var used:Int = 0
    
    init(station:Station) {
        self.station = station
    }
}

class MostUsed {
    
    class func getList() -> [NSString] {
        let defaults = NSUserDefaults.standardUserDefaults()
        let arr = defaults.arrayForKey(MOSTUSEDKEY)
        if let a = arr {
            return a.map { $0 as NSString }
        } else {
            return []
        }
    }
    
    class func addStation(station:Station) {
        var list = getList()
        list.insert(station.code, atIndex: 0)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(list, forKey: MOSTUSEDKEY)
        defaults.synchronize()
    }
    
    class func getListByVisited() -> Array<Station> {
        let list = getList()
        
        var dict = Dictionary<NSString, Int>()
        
        for station in list {
            if let i = dict[station] {
                dict[station] = i+1
            } else {
                dict[station] = 1
            }
        }
        
        var stations:Array<NSString> = Array(dict.keys)
        sort(&stations) {
            var obj1 = dict[$0] // get ob associated w/ key 1
            var obj2 = dict[$1] // get ob associated w/ key 2
            return obj1 > obj2
        }
        
        return stations.map { find(TreinTicker.sharedInstance.stations, $0)! }
    }
    
}