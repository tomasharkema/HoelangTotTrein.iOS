//
//  Station.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreLocation

struct Namen {
    let kort:String
    let middel:String
    let lang:String
    
    func string() -> String {
        return lang
    }
}

let RADIUS:CLLocationDistance = 150

class Station: NSObject, NSCoding {
    
    let code:String!
    let type:String!
    let name:Namen!
    let land:String!
    let lat:Double!
    let long:Double!
    
    let UICCode:Int
    //let synoniemen:[String]
    
    override var hashValue: Int {
        return self.code.toInt()!
    }

    override var hash:Int {
        return self.code.toInt()!
    }
    
    let stationData:AEXMLElement
  
    required init(coder aDecoder: NSCoder) {
        self.code = aDecoder.decodeObjectForKey("code") as String?
        self.type = aDecoder.decodeObjectForKey("type") as String?
        self.land = aDecoder.decodeObjectForKey("land") as String?
        self.lat = aDecoder.decodeDoubleForKey("lat")
        self.long = aDecoder.decodeDoubleForKey("long")
        self.UICCode = aDecoder.decodeIntegerForKey("UICCode")
        self.name = Namen(kort: aDecoder.decodeObjectForKey("name.kort") as String!, middel: aDecoder.decodeObjectForKey("name.middel") as String!, lang: aDecoder.decodeObjectForKey("name.lang") as String!)
        self.stationData = AEXMLDocument()
        super.init()
    }
  
    func encodeWithCoder(aCoder: NSCoder) {
      aCoder.encodeObject(self.code, forKey: "code")
      aCoder.encodeObject(self.type, forKey: "type")
      aCoder.encodeObject(self.land, forKey: "land")
      aCoder.encodeDouble(self.lat, forKey: "lat")
      aCoder.encodeDouble(self.long, forKey: "long")
      aCoder.encodeInteger(self.UICCode, forKey: "UICCode")
      aCoder.encodeObject(self.name.kort, forKey: "name.kort")
      aCoder.encodeObject(self.name.middel, forKey: "name.middel")
      aCoder.encodeObject(self.name.lang, forKey: "name.lang")
    }
  
    init (obj:AEXMLElement) {
      stationData = obj
      code    = obj["Code"]?.stringValue
      type    = obj["Type"]?.stringValue
      land    = obj["Land"]?.stringValue
      lat     = obj["Lat"]?.doubleValue
      long    = obj["Lon"]?.doubleValue
      UICCode = obj["UICCode"]?.intValue ?? 0;
      
      
      let namen: AEXMLElement = obj["Namen"]!
      
      let kort = namen["Kort"];
      let middel = namen["Middel"];
      let lang = namen["Lang"];
      
      name = Namen(kort: kort?.stringValue ?? "", middel: middel?.stringValue ?? "", lang: lang?.stringValue ?? "")
    }
    
    func getLocation() -> CLLocation {
        return CLLocation(latitude: lat!, longitude: long!)
    }
    
    func getRegion(i:Int) -> CLRegion {
        let center = getLocation().coordinate
        return CLCircularRegion(center: center, radius: RADIUS, identifier: CodeContainer(namespace: .Station, code: code, deelIndex: i).string())
    }
    
    class func sortStation(stations:Array<Station>, sortableRepresentation:(a:Station) -> Double, sorter:(a:Double, b:Double) -> Bool, number:Int = -1) -> Array<Station> {
        var dict = Dictionary<NSString, Double>()
        
        for station in stations {
            dict[station.code] = sortableRepresentation(a: station)
        }
        
        var stationsK:Array<NSString> = Array(dict.keys)
        
        sort(&stationsK) { a, b -> Bool in
            return sorter(a:dict[a]!, b:dict[b]!)
        }
      
        return stationsK.slice(number).map { find(stations, $0)! }
    }
  
    class func getClosestStation(stations: Array<Station>,loc:CLLocation) -> Station? {
        var currentStation:Station
        var closestDistance:CLLocationDistance = DBL_MAX
        var closestStation:Station?
        
        for station in stations {
            let dist = station.getLocation().distanceFromLocation(loc)
            if (dist < closestDistance) {
                closestStation = station;
                closestDistance = dist;
            }
        }
        return closestStation
    }
  
    class func sortStationsOnLocation(stations: Array<Station>, loc:CLLocation, sorter:(a:Double, b:Double) -> Bool, number:Int = -1) -> Array<Station> {
        return sortStation(stations, sortableRepresentation: {
          return $0.getLocation().distanceFromLocation(loc)
          }, sorter: sorter, number:number)
    }
}

func ==(lhs: Station, rhs: Station) -> Bool {
    return lhs.code == rhs.code
}

func find(stations:Array<Station>, code:String) -> Station? {
    return stations.filter{ $0.code == code }.first
}

func find(stations:Array<Station>, station:Station) -> Station? {
    return find(stations, station.code)
}

func findIndex(stations:Array<Station>, station:Station) -> Int? {
    var i = 0
    var index:Int?
    for s in stations {
        if s == station {
            index = i
        }
        i++
    }
    
    return index
}