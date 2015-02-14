//
//  Station.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Ono
import CoreLocation

struct Namen {
    let kort:String
    let middel:String
    let lang:String
    
    func string() -> String {
        return lang
    }
}

let RADIUS:CLLocationDistance = 50

class Station: Hashable {
    
    let code:String!
    let type:String!
    let name:Namen!
    let land:String!
    let lat:Double!
    let long:Double!
    
    let UICCode:Int
    //let synoniemen:[String]
    
    var hashValue: Int {
        return self.code.toInt()!
    }
    
    let stationData:ONOXMLDocument
    
    init (obj:ONOXMLElement) {
        stationData = obj.document

        code    = obj.string(tagName: "Code")
        type    = obj.string(tagName: "Type")
        land    = obj.string(tagName: "Land")
        lat     = obj.double(tagName: "Lat")
        long    = obj.double(tagName: "Lon")
        UICCode = obj.int(tagName: "UICCode")!
        
        let el:ONOXMLElement = (obj.childrenWithTag("Namen")[0] as? ONOXMLElement)!
        
        name = Namen(
            kort: (el.childrenWithTag("Kort").first as ONOXMLElement).stringValue(),
            middel: (el.childrenWithTag("Middel").first as ONOXMLElement).stringValue(),
            lang: (el.childrenWithTag("Lang").first as ONOXMLElement).stringValue())
    }
    
    func getLocation() -> CLLocation {
        return CLLocation(latitude: lat!, longitude: long!)
    }
    
    func getRegion(i:Int) -> CLRegion {
        let center = getLocation().coordinate
        return CLCircularRegion(center: center, radius: RADIUS, identifier: CodeContainer(namespace: "STATION:", code: code, deelIndex: i).string())
    }
}

func ==(lhs: Station, rhs: Station) -> Bool {
    return lhs.code == rhs.code
}

func find(advices:Array<Station>, code:String?) -> Station? {
    if let code = code {
        return advices.filter{ $0.code == code }.first
    } else {
        return nil
    }
}