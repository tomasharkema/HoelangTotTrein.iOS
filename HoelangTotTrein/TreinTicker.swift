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

struct CodeContainer {
    let namespace:String
    let code:String
    let deelIndex:Int
    
    func string() -> String {
        return "\(namespace):\(code):\(deelIndex)"
    }
    
    static func getFromString(string:String) -> CodeContainer {
        let components = split(string) {$0 == ":"}
        return CodeContainer(namespace: components.first!, code: components[1], deelIndex: NSString(string:components.last!).integerValue)
    }
}

private var treinTickerSharedInstance:TreinTicker!

class TreinTicker: NSObject, CLLocationManagerDelegate {
    
    var stations:Array<Station> = []
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
            return find(stations, NSUserDefaults.standardUserDefaults().stringForKey("originalFromKey")!)
        }
        set (newOriginalFrom) {
            NSUserDefaults.standardUserDefaults().setValue(newOriginalFrom.code, forKey: "originalFromKey")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var from:Station! {
        didSet {
            //fromButton.setTitle(from.naam.lang, forState: UIControlState.Normal)
            if (from != nil && to != nil && fromToChanged != nil) {
                fromToChanged(from: from, to: to)
                adviceRequest = AdviceRequest(from: from, to: to)
            }
            NSUserDefaults.standardUserDefaults().setValue(from.code, forKey: "fromKey")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            MostUsed.addStation(from)
        }
    }
    var to:Station! {
        didSet {
            //toButton.setTitle(to.naam.lang, forState: UIControlState.Normal)
            if (from != nil && to != nil && fromToChanged != nil) {
                fromToChanged(from: from, to: to)
                adviceRequest = AdviceRequest(from: from, to: to)
            }
            NSUserDefaults.standardUserDefaults().setValue(to.code, forKey: "toKey")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            MostUsed.addStation(to)
        }
    }
    
    func setInitialState() {
        let defaults = NSUserDefaults.standardUserDefaults()
        from = find(stations, defaults.stringForKey("fromKey")!) ?? stations.first
        to = find(stations, defaults.stringForKey("toKey")!) ?? stations.first
        
        adviceRequest = AdviceRequest(from: from!, to: to!)
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
        }
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
        
        from = arrivedStation
        
        let notification = UILocalNotification()
        let vervolgStation = currentAdivce.reisDeel[code.deelIndex + 1].stops.first?
        let vervolgStationTime:String! = vervolgStation?.time!.toHHMM().string()
        let vervolgSpoor:String! = vervolgStation?.spoor
        let aankomstStation:String! = arrivedStation?.name.lang
        
        let vervolgString = vervolgStationTime + " vanaf spoor " + vervolgSpoor
        
        notification.alertBody = "Je bent nu aangekomen bij \(aankomstStation). Je vervolgtrein vertrekt om " + vervolgString
        notification.fireDate = NSDate()
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
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
