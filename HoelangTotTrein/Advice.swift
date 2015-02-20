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

struct Melding {
  let id:String
  let ernstig:Bool
  let text:String
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

class Advice: NSObject, NSCoding {
  
  let obj: ONOXMLElement
  
  let overstappen:Int
  let vertrek:OVTime
  let aankomst:OVTime
  let melding:Melding?
  
  let reisDeel: [ReisDeel]
  
  let adviceRequest:AdviceRequest
  let vertrekVertraging:String!
  
  init(obj: ONOXMLElement, adviceRequest:AdviceRequest) {
    self.obj = obj
    self.adviceRequest = adviceRequest
    
    overstappen = (obj.childrenWithTag("AantalOverstappen").first as ONOXMLElement).numberValue().integerValue
    
    let geplandeVertrekTijd = (obj.childrenWithTag("GeplandeVertrekTijd").first as ONOXMLElement)
    vertrek = OVTime(planned:geplandeVertrekTijd.dateValue(),
      actual: (obj.childrenWithTag("ActueleVertrekTijd").first as? ONOXMLElement ?? geplandeVertrekTijd).dateValue())
    
    let geplandeAankomstTijd = (obj.childrenWithTag("GeplandeAankomstTijd").first as ONOXMLElement)
    aankomst = OVTime(planned:geplandeAankomstTijd.dateValue(),
      actual: (obj.childrenWithTag("ActueleAankomstTijd").first as? ONOXMLElement ?? geplandeAankomstTijd).dateValue())
    
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
    
    if let mel = obj.getElement("Melding") {
      melding = Melding(id: mel.string(tagName: "Id")!, ernstig: false, text: mel.string(tagName: "Text")!)
    }
    
    if let vertraging = obj.string(tagName: "VertrekVertraging") {
      vertrekVertraging = vertraging
    }
  }
  
  required convenience init(coder aDecoder: NSCoder) {
    let obj = ONOXMLElement(coder: aDecoder)
    let from = aDecoder.decodeObjectForKey("from") as Station
    let to = aDecoder.decodeObjectForKey("to") as Station
    self.init(obj:obj, adviceRequest:AdviceRequest(from: from, to: to))
  }
  
  func encodeWithCoder(aCoder: NSCoder) {
    obj.encodeWithCoder(aCoder)
    aCoder.encodeObject(adviceRequest.from, forKey: "from")
    aCoder.encodeObject(adviceRequest.to, forKey: "to")
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