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
private var treinTickerShareExtensiondInstance:TreinTicker!

class TreinTicker: NSObject, CLLocationManagerDelegate {
  
  var stations:Array<Station> {
    set {
      UserDefaults.stations = newValue
    }
    get {
      return UserDefaults.stations as [Station]
    }
  }
  
  var isExtention: Bool = false
  
  var adviceOffset:NSDate?
  
  var heartBeat:NSTimer!
  var minuteTicker:Int = 0
  var advices:[Advice] {
    get {
      return UserDefaults.advices
    }
    set {
      UserDefaults.advices = newValue
    }
  }
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
  
  class var sharedExtensionInstance: TreinTicker {
    if treinTickerShareExtensiondInstance == nil {
      treinTickerShareExtensiondInstance = TreinTicker()
    }
    treinTickerShareExtensiondInstance.isExtention = true
    return treinTickerShareExtensiondInstance
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
    if (!isExtention) {
      API().getStations { [weak self] stations in
        let s:Array<Station> = stations
        self?.stations = s
        self?.setInitialState()
        
        if let cb = self?.stationChangedHandler {
          cb(s)
        }
      }
    }
  }
  
  var currentAdivce:Advice! {
    set {
      UserDefaults.currentAdvice = newValue
      let currentAdvice = newValue
      
      if (adviceChangedHandler != nil && currentAdvice != nil) {
        adviceChangedHandler(currentAdvice)
      }
      
      if isExtention {
        return;
      }
      
      for region in locationManager.monitoredRegions.allObjects {
        if let r = region as? CLRegion {
          println("STOP OBSERVING FOR \(findStationByCode(CodeContainer.getFromString(r.identifier))!.name.lang)")
          locationManager.stopMonitoringForRegion(r)
        }
      }
      var i = 0
      for deel in currentAdvice.reisDeel {
        let target = deel.stops.last
        let station = stations.filter {
          $0.name.lang == target?.name
          }.first
        
        locationManager.startMonitoringForRegion(station?.getRegion(i))
        i++
      }
    }
    get {
      return UserDefaults.currentAdvice
    }
  }
  
  private var adviceRequest:AdviceRequest! {
    didSet {
      adviceOffset = nil
      changeRequest()
      minuteTicker = 0
    }
  }
  
  var originalFrom:Station! {
    get {
      return find(stations, UserDefaults.originalFrom)
    }
    set {
      UserDefaults.originalFrom = newValue.code
    }
  }
  
  var from:Station! {
    set {
      UserDefaults.from = newValue.code
      if (newValue != nil && to != nil && fromToChanged != nil) {
        fromToChanged(from: newValue, to: to)
        adviceRequest = AdviceRequest(from: newValue, to: to)
      }
      
      MostUsed.addStation(newValue)
    }
    get {
      return find(stations, UserDefaults.from) ?? stations.first
    }
  }
  var to:Station! {
    set {
      UserDefaults.to = newValue.code
      if (from != nil && newValue != nil && fromToChanged != nil) {
        fromToChanged(from: from, to: newValue)
        adviceRequest = AdviceRequest(from: from, to: newValue)
      }
      
      MostUsed.addStation(newValue)
    }
    get {
      return find(stations, UserDefaults.to) ?? stations[5] ?? nil
    }
    
  }
  
  func setInitialState() {
    adviceRequest = AdviceRequest(from: from, to: to)
    if let cb = fromToChanged {
      cb(from: from, to: to)
    }
  }
  
  func start() {
    if (heartBeat != nil) {
      return;
    }
    if (UserDefaults.currentAdvice != nil) {
      currentAdivce = UserDefaults.currentAdvice
    }
    
    heartBeat = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timerCallback"), userInfo: nil, repeats: true)
    if let advice = currentAdivce {
      if let cb = adviceChangedHandler {
        cb(advice)
      }
    }
    if from != nil && to != nil {
      if let cb = fromToChanged {
        fromToChanged(from: from, to: to)
      }
    }
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
      currentAdviceRequest = nil
    }
    
    currentAdviceRequest = API().getAdvice(self.adviceRequest) { advices in
      let a:Array<Advice> = advices;
      self.advices = a
      
      if let cb = self.updateCallback {
        if let adv = self.getCurrentAdvice() {
          cb(adv)
          self.updateCallback = nil
        }
      }
      
    }
  }
  
  var updateCallback:((Advice) -> Void)!
  func updateAdvice(cb:(Advice) -> Void) {
    updateCallback = cb
  }
  
  func getUpcomingAdvices() -> [Advice] {
    let advicesSorted = sorted(advices) { a,b in
      a.vertrek.actual.timeIntervalSince1970 < b.vertrek.actual.timeIntervalSince1970
    }
    
    return advicesSorted.filter {
      $0.vertrek.actual.timeIntervalSinceNow > 0
    }
  }
  
  func getUpcomingAdvicesWithOffset() -> [Advice] {
    return getUpcomingAdvices().filter{ $0.vertrek.planned.timeIntervalSince1970 >= self.adviceOffset?.timeIntervalSince1970 }
  }
  
  func getAdviceOffset() -> Int {
    return indexOf(advices, currentAdivce)
  }
  
  func getCurrentAdvice() -> Advice? {
    let adivces = getUpcomingAdvices()
    
    // filter advice als er een offset is gezet. Hierdoor kan je een later advies zetten, maar vallen de latere gewoon door tot de eerste.
    if let adviceOffsetDate = adviceOffset {
      return getUpcomingAdvicesWithOffset().first
    } else {
      return adivces.first
    }
  }
  
  func timerCallback() {
    if (tickerHandler != nil && adviceRequest != nil) {
      if let currentAdv = getCurrentAdvice() {
        if let currentAdvice = self.currentAdivce {
          if (currentAdvice != currentAdv) {
            println("upcoming advices: \(getUpcomingAdvices().count)")
            self.currentAdivce = currentAdv
          }
        } else {
          self.currentAdivce = currentAdv
        }
        
        tickerHandler(currentAdv.vertrek.actual.toMMSSFromNow())
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
  
  func skipCurrentAdvice() {
    let upcoming = getUpcomingAdvicesWithOffset()
    
    adviceOffset = upcoming[min(upcoming.count-1, 1)].vertrek.planned
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
      //to = originalFrom!
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
    locationManager.stopMonitoringForRegion(region)
    let code = CodeContainer.getFromString(region.identifier)
    let arrivedStation = findStationByCode(code)
    println("DID ENTER REGION: \(arrivedStation!.name.lang)")
    
    if (currentAdivce?.reisDeel.count <= (code.deelIndex + 1)) {
      // final destination
      switchAdviceRequestOriginal()
      originalFrom = to
      return;
    }
    
    updateAdvice {
      let notificationBody = $0.notificationPhrase(code.deelIndex)
      
      let notification = UILocalNotification()
      notification.alertBody = notificationBody
      notification.fireDate = NSDate()
      notification.soundName = UILocalNotificationDefaultSoundName
      
      NSNotificationCenter.defaultCenter().postNotificationName("showNotification", object: notification)
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
    }
  }
}
