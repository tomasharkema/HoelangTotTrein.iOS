//
//  Station.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Ono

struct Namen {
    let kort:String
    let middel:String
    let lang:String
}

class Station: Hashable {
    
    let code:String!
    let type:String!
    let naam:Namen!
    let land:String!
    //let UICCode:Int
    //let synoniemen:[String]
    
    var hashValue: Int {
        return self.code.toInt()!
    }
    
    let stationData:ONOXMLDocument
    
    init (obj:ONOXMLElement) {
        stationData = obj.document

        code = (obj.childrenWithTag("Code").first as ONOXMLElement).stringValue()
        type = (obj.childrenWithTag("Type").first as ONOXMLElement).stringValue()
        land = (obj.childrenWithTag("Land").first as ONOXMLElement).stringValue()
        
        if let el:ONOXMLElement = (obj.childrenWithTag("Namen")[0] as? ONOXMLElement) {
            naam = Namen(
                kort: (el.childrenWithTag("Kort").first as ONOXMLElement).stringValue(),
                middel: (el.childrenWithTag("Middel").first as ONOXMLElement).stringValue(),
                lang: (el.childrenWithTag("Lang").first as ONOXMLElement).stringValue())
        } else {
            naam = nil
        }
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