//
//  TreinTicker.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 11-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

typealias TickerHandler = (HHMMSS) -> Void
typealias AdviceChangedHandler = (Advice) -> Void
typealias StationsChangeHandler = (Array<Station>) -> Void
typealias FromToChanged = (from:Station?, to:Station?) -> Void

enum NotificationNamespace: String {
  case Station = "Station"
  
  static func fromString(namespace: String) -> NotificationNamespace {
    switch namespace {
    default:
      return .Station
    }
  }
}

struct CodeContainer {
    let namespace:NotificationNamespace
    let code:String
    let deelIndex:Int
    
    func string() -> String {
        return "\(namespace):\(code):\(deelIndex)"
    }
    
    static func getFromString(string:String) -> CodeContainer {
        let components = split(string) {$0 == ":"}
        return CodeContainer(namespace: NotificationNamespace.fromString(components.first!), code: components[1], deelIndex: NSString(string:components.last!).integerValue)
    }
}

private var treinTickerSharedInstance:TreinTicker!

class TreinTicker: NSObject, CLLocationManagerDelegate {
    
    var stations:Array<Station> {
      set {
        NSUserDefaults.standardUserDefaults().stations = newValue
      }
      get {
        return NSUserDefaults.standardUserDefaults().stations as [Station]
      }
    }
  
    var heartBeat:NSTimer!
    var minuteTicker:Int = 0
    var advices:Array<Advice> = []
    var currentLocation:CLLocation!
    
    var tickerHandler:TickerHandler!
    var adviceChangedHandler:AdviceChangedHandler!
    var stationChangedHandler:StationsChangeHandler!
    var fromToChanged:FromToChanged!
    
    var locationManager:CLLocationManager
    var geofences:[CLRegion] = []
    
    var currentAdviceRequest:Request!
    
    class var sharedInstance: TreinTicker {
        if treinTickerSharedInstance == nil {
            treinTickerSharedInstance = TreinTicker()
        }
        return treinTickerSharedInstance
    }
    
    private override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        
        locationManager.requestAlwaysAuthorization()
      
        if stations.count > 0 {
          
          self.setInitialState()
          if let cb = stationChangedHandler {
            cb(stations)
          }
        }
      
        API().getStations { [weak self] stations in
            let s:Array<Station> = stations
            self?.stations = s
            self?.setInitialState()
            
            if let cb = self?.stationChangedHandler {
                cb(s)
            }
        }
    }
    
    var currentAdivce:Advice! {
        didSet {
            if (adviceChangedHandler != nil) {
                adviceChangedHandler(currentAdivce)
            }
            
            for region in locationManager.monitoredRegions.allObjects {
                if let r = region as? CLRegion {
                    println("STOP OBSERVING FOR \(findStationByCode(CodeContainer.getFromString(r.identifier))!.name.lang)")
                    locationManager.stopMonitoringForRegion(r)
                }
            }
            var i = 0
            for deel in currentAdivce.reisDeel {
                let target = deel.stops.last
                let station = stations.filter {
                    $0.name.lang == target?.name
                }.first
                
                locationManager.startMonitoringForRegion(station?.getRegion(i))
                i++
            }
        }
    }
    
    private var adviceRequest:AdviceRequest! {
        didSet {
            changeRequest()
            minuteTicker = 0
        }
    }
    
    var originalFrom:Station! {
        get {
            return find(stations, NSUserDefaults.standardUserDefaults().originalFrom)
        }
        set {
            NSUserDefaults.standardUserDefaults().originalFrom = newValue.code
        }
    }
    
    var from:Station! {
      set {
        NSUserDefaults.standardUserDefaults().from = newValue.code
        if (newValue != nil && to != nil && fromToChanged != nil) {
          fromToChanged(from: newValue, to: to)
          adviceRequest = AdviceRequest(from: newValue, to: to)
        }
        
        MostUsed.addStation(newValue)
      }
      get {
        return find(stations, NSUserDefaults.standardUserDefaults().from) ?? stations.first
      }
    }
    var to:Station! {
      set {
        NSUserDefaults.standardUserDefaults().to = newValue.code
        if (from != nil && newValue != nil && fromToChanged != nil) {
            fromToChanged(from: from, to: newValue)
            adviceRequest = AdviceRequest(from: from, to: newValue)
        }
        
        MostUsed.addStation(newValue)
      }
      get {
        return find(stations, NSUserDefaults.standardUserDefaults().to) ?? stations.first
      }
      
    }
    
    func setInitialState() {
      adviceRequest = AdviceRequest(from: from, to: to)
      if let cb = fromToChanged {
        cb(from: from, to: to)
      }
    }
    
    func start() {
        heartBeat = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timerCallback"), userInfo: nil, repeats: true)
    }
    
    func stop() {
        if (heartBeat != nil) {
            heartBeat.invalidate()
            heartBeat = nil;
        }
    }
    
    func changeRequest() {
        if currentAdviceRequest != nil {
            currentAdviceRequest.cancel()
        }
        
        currentAdviceRequest = API().getAdvice(adviceRequest) { [weak self] advices in
            let a:Array<Advice> = advices;
            self?.advices = a
            
            if let cb = self?.updateCallback {
                if let adv = self?.getCurrentAdvice() {
                    cb(adv)
                    self?.updateCallback = nil
                }
            }
        }
    }
    
    var updateCallback:((Advice) -> Void)!
    func updateAdvice(cb:(Advice) -> Void) {
        updateCallback = cb
    }
    
    func getCurrentAdvice() -> Advice? {
        return advices.filter {
            $0.vertrek.actual.timeIntervalSinceNow > 0
         }.first
    }
    
    func timerCallback() {
        if (tickerHandler != nil && adviceRequest != nil) {
            if let currentAdv = getCurrentAdvice() {
                if let currentAdvice = self.currentAdivce {
                    if (self.currentAdivce != currentAdv) {
                        self.currentAdivce = currentAdv
                    }
                } else {
                    self.currentAdivce = currentAdv
                }
                
                
                tickerHandler(currentAdivce.vertrek.actual.toMMSSFromNow())
            }
        }
        
        if (minuteTicker > 30) {
            if (currentAdivce != nil) {
                changeRequest();
            }
            minuteTicker = 0
        }
        minuteTicker++;
    }
    
    func findStationByCode(code:CodeContainer) -> Station? {
        return stations.filter {
            $0.code == code.code
        }.first
    }
    
    func saveOriginalFrom() {
        originalFrom = from
    }
    
    func switchAdviceRequest() {
        let newTo = from
        let newFrom = to
        to = newTo
        from = newFrom
    }
    
    func switchAdviceRequestOriginal() {
        switchAdviceRequest()
        if originalFrom != nil {
            to = originalFrom!
        }
    }
    
    var shouldUpdate:Bool = false
    
    func fromCurrentLocation() {
        shouldUpdate = true
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        println("START OBSERVING FOR \(findStationByCode(CodeContainer.getFromString(region.identifier))!.name.lang)")
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR! \(error.description)")
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        let code = CodeContainer.getFromString(region.identifier)
        let arrivedStation = findStationByCode(code)
        println("DID ENTER REGION: \(arrivedStation!.name.lang)")
        
        if (currentAdivce.reisDeel.count <= (code.deelIndex + 1)) {
            // final destination
            switchAdviceRequestOriginal()
            originalFrom = to
            return;
        }
        
        let vervolgStation = currentAdivce.reisDeel[code.deelIndex + 1].stops.first?
        
        var vervolgStationTime:String! = ""
        var vervolgSpoor:String! = ""
        var aankomstStation:String! = ""
        
        let sendNotification:(String, String, String) -> Void = { vervolgStationTime, vervolgSpoor, aankomstStation in
            let notification = UILocalNotification()
            let vervolgString = vervolgStationTime + " vanaf spoor " + vervolgSpoor
            
            notification.alertBody = "Je vervolgtrein vertrekt om " + vervolgString
            notification.fireDate = NSDate()
            
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
        
        if (vervolgStation?.time?.timeIntervalSinceNow < 0 ) {
            
            // Advice is veroudert.
            println("Veroudert")
            updateAdvice {
                println("Nieuw advice")
                let newStation = $0.firstStop()
                let vervolgStationTime = newStation?.time!.toHHMM().string()
                let vervolgSpoor = newStation?.spoor
                let aankomstStation = arrivedStation?.name.lang
                
                sendNotification(vervolgStationTime!, vervolgSpoor!, aankomstStation!)
            }
            
        } else {
            println("Toon Notificatie")
            vervolgStationTime = vervolgStation?.time!.toHHMM().string()
            vervolgSpoor = vervolgStation?.spoor
            aankomstStation = arrivedStation?.name.lang
            sendNotification(vervolgStationTime, vervolgSpoor, aankomstStation)
        }
        
        from = arrivedStation
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        println("DID LEAVE REGION: \(region.identifier)")
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        manager.stopUpdatingLocation()
        if (!shouldUpdate) {
            return
        }
        
        shouldUpdate = false
        
        currentLocation = locations[0] as? CLLocation
        
        let closest = Station.getClosestStation(stations, loc: currentLocation!)
        if (closest! == to!) {
            switchAdviceRequest()
        } else {
            from = closest
            originalFrom = from
        }
    }
}
