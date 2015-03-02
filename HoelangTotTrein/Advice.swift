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

class Advice: NSObject, NSCoding, Hashable {
  
  let overstappen:Int
  let vertrek:OVTime
  let aankomst:OVTime
  let melding:Melding?
  
  let reisDeel: [ReisDeel]
  
  let adviceRequest:AdviceRequest
  let vertrekVertraging:String?
  
  init(obj: ONOXMLElement, adviceRequest:AdviceRequest) {
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
  
  required init(coder aDecoder: NSCoder) {
    adviceRequest = AdviceRequest(from: aDecoder.decodeObjectForKey("from") as Station, to: aDecoder.decodeObjectForKey("to") as Station)
    
    overstappen = aDecoder.decodeIntegerForKey("overstappen")
    
    vertrek = OVTime(planned: NSDate(timeIntervalSinceReferenceDate: aDecoder.decodeDoubleForKey("vertrek.planned")), actual: NSDate(timeIntervalSinceReferenceDate: aDecoder.decodeDoubleForKey("vertrek.actual")))
    
    aankomst = OVTime(planned: NSDate(timeIntervalSinceReferenceDate: aDecoder.decodeDoubleForKey("aankomst.planned")), actual: NSDate(timeIntervalSinceReferenceDate: aDecoder.decodeDoubleForKey("aankomst.actual")))
    
    reisDeel = (aDecoder.decodeObjectForKey("reisDeel") as [NSData]).map { data in
      let data = NSKeyedUnarchiver.unarchiveObjectWithData(data) as [AnyObject]
      let stops:[Stop] = (data[1] as [AnyObject]).map { obj in
        let data = obj as [AnyObject]
        return Stop(time: data[0] as? NSDate, spoor: data[1] as? String, name: data[2] as? String ?? "")
      }
      return ReisDeel(vervoerder: data[0] as String, stops: stops)
    }
    
    if let m = aDecoder.decodeObjectForKey("melding.id") {
      melding = Melding(id: aDecoder.decodeObjectForKey("melding.id") as String, ernstig: aDecoder.decodeBoolForKey("melding.ernstig"), text: aDecoder.decodeObjectForKey("melding.text") as String)
    }
  }
  
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(adviceRequest.from, forKey: "from")
    aCoder.encodeObject(adviceRequest.to, forKey: "to")
    
    aCoder.encodeInteger(overstappen, forKey: "overstappen")
    
    aCoder.encodeDouble(aankomst.planned.timeIntervalSinceReferenceDate, forKey: "aankomst.planned")
    aCoder.encodeDouble(aankomst.actual.timeIntervalSinceReferenceDate, forKey: "aankomst.actual")
    aCoder.encodeDouble(vertrek.planned.timeIntervalSinceReferenceDate, forKey: "vertrek.planned")
    aCoder.encodeDouble(vertrek.actual.timeIntervalSinceReferenceDate, forKey: "vertrek.actual")
    
    let encodeReisDeel: [NSData] = reisDeel.map { deel in
      let encodeStops:[[AnyObject]] = deel.stops.map { stop in
        let arr: [AnyObject] = [stop.time!, stop.spoor ?? "", stop.name]
        return arr
      }
      
      let encodedData = [
        deel.vervoerder,
        encodeStops
      ]
      
      return NSKeyedArchiver.archivedDataWithRootObject(encodedData)
    }
    
    aCoder.encodeObject(encodeReisDeel, forKey: "reisDeel")
    
    if let m = melding {
      aCoder.encodeBool(m.ernstig, forKey: "melding.ernstig")
      aCoder.encodeObject(m.id, forKey: "melding.id")
      aCoder.encodeObject(m.text, forKey: "melding.text")
    }
  }
  
  func firstStop() -> Stop? {
    return reisDeel.first?.stops.first
  }
  
  func lastStop() -> Stop? {
    return reisDeel.last?.stops.last
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
  
  func notificationPhrase(deelIndex:Int) -> String {
    let vervolg = self.reisDeel[min(deelIndex + 1, self.reisDeel.count-1)].stops
    let vervolgStation = vervolg.first?
    let aankomst = vervolg.last?.name ?? "??"
    
    let newStation = self.firstStop()
    let vervolgStationTime:String = newStation?.time!.toHHMM().string() ?? ""
    let vervolgStationToGo:String = newStation?.time?.toMMSSFromNow().string() ?? ""
    let vervolgSpoor:String = newStation?.spoor ?? ""
    
    return "De trein naar \(aankomst) vertrekt over " + vervolgStationToGo + " min (" + vervolgStationTime + "u) van spoor " + vervolgSpoor
  }
}

func ==(a:Advice, b:Advice) -> Bool {
  return a.vertrek.actual == b.vertrek.actual &&
    a.vertrek.planned == b.vertrek.planned &&
    a.aankomst.actual == b.aankomst.actual &&
    a.aankomst.planned == b.aankomst.planned &&
    a.adviceRequest.from.code == b.adviceRequest.from.code &&
    a.adviceRequest.to.code == b.adviceRequest.to.code
}

func !=(a:Advice, b:Advice) -> Bool {
  return !(a == b)
}

func indexOf(advices:[Advice], objectToCompare: Advice) -> Int {
  var index = 0
  for obj in advices {
    if obj == objectToCompare {
      return index
    }
    index++
  }
  return -1
}