//
//  Advice.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Ono
import CoreLocation

struct OVTime {
    let planned:NSDate
    let actual:NSDate
    
    func getFormattedString() -> String {
        let hhmm = actual.toHHMM()
        return "\(hhmm.hour):\(hhmm.minute)"
    }
}

struct Stop {
    let time:NSDate?
    let spoor:String?
    let name:String
}

struct ReisDeel {
    let vervoerder:String
    let stops:Array<Stop>
    
    func getRegion() -> CLRegion {
        
        let target = stops.last!
        
        return CLCircularRegion()
    }
}

class Advice {
    
    let overstappen:Int
    let vertrek:OVTime
    let aankomst:OVTime
    
    let reisDeel:Array<ReisDeel>
    
    let adviceRequest:AdviceRequest
    
    init(obj: ONOXMLElement, adviceRequest:AdviceRequest) {
        self.adviceRequest = adviceRequest
        
        overstappen = (obj.childrenWithTag("AantalOverstappen").first as ONOXMLElement).numberValue().integerValue
        
        vertrek = OVTime(planned:(obj.childrenWithTag("GeplandeVertrekTijd").first as ONOXMLElement).dateValue(),
            actual: (obj.childrenWithTag("ActueleVertrekTijd").first as ONOXMLElement).dateValue())
        
        aankomst = OVTime(planned:(obj.childrenWithTag("GeplandeAankomstTijd").first as ONOXMLElement).dateValue(),
            actual: (obj.childrenWithTag("ActueleAankomstTijd").first as ONOXMLElement).dateValue())
        
        reisDeel = obj.childrenWithTag("ReisDeel").map { reisDeelObj in
            let reisDeel:ONOXMLElement = reisDeelObj as ONOXMLElement
            let vervoerder = "NS"
            
            let stopDelen = reisDeel.childrenWithTag("ReisStop")
            let stopElements = stopDelen.map { el in
                el as ONOXMLElement
            }
            
            let stops:Array<Stop> = stopElements.map { stopEl in
                let stop = stopEl as ONOXMLElement
                let spoor = (stop.childrenWithTag("Spoor").first as? ONOXMLElement)?.stringValue()
                let time = (stop.childrenWithTag("Tijd").first as ONOXMLElement).dateValue()
                let naam = (stop.childrenWithTag("Naam").first as ONOXMLElement).stringValue()
                return Stop(time: time, spoor: spoor, name: naam)
            }
            
            return ReisDeel(vervoerder: vervoerder, stops: stops)
        }
    }
    
    func firstStop() -> Stop? {
        return reisDeel.first?.stops.first
    }
    
    func legPhraseLeft() -> String {
        if reisDeel.count > 1 {
            return reisDeel.reduce("", { str, deel in
                var firstStop = deel.stops.first
                var lastStop = deel.stops.last
                
                return str + "\(firstStop!.name) (\(firstStop!.spoor!))\n"
            })
        } else {
            return ""
        }
    }
    
    func legPhraseRight() -> String {
        if (reisDeel.count > 1) {
            return reisDeel.reduce("") { str, deel in
                var firstStop = deel.stops.first
                var lastStop = deel.stops.last
                return  str + ">  (\(lastStop!.spoor!)) \(lastStop!.name)\n"
            }
        } else {
            return ""
        }
    }
}

func ==(a:Advice, b:Advice) -> Bool {
    return a.vertrek.actual == b.vertrek.actual &&
    a.vertrek.planned == b.vertrek.planned &&
    a.aankomst.actual == b.aankomst.actual &&
    a.aankomst.planned == b.aankomst.planned
}

func !=(a:Advice, b:Advice) -> Bool {
    return !(a == b)
}