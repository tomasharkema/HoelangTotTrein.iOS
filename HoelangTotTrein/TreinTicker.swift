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
import Observable

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

struct FromTo {
  let from: Station?
  let to: Station?
}

private var treinTickerSharedInstance:TreinTicker!
private var treinTickerShareExtensionInstance:TreinTicker!

class TreinTicker: NSObject {
  
  var stations:Array<Station> {
    set {
      UserDefaults.stations = newValue
    }
    get {
      return UserDefaults.stations as [Station]
    }
  }
  
  let isExtention: Bool
  
  var adviceOffset:NSDate? {
    get {
      return UserDefaults.adviceOffset
    }
    set {
      UserDefaults.adviceOffset = newValue
    }
  }
  
  var heartBeat:NSTimer!
  var minuteTicker:Int = 0
  
  var _advices:[Advice]?
  var advices:[Advice] {
    get {
      if _advices == nil {
        let advices = UserDefaults.advices
        _advices = advices
        return advices
      } else {
        return _advices!
      }
    }
    set {
      _advices = newValue
      UserDefaults.advices = newValue
    }
  }
  
  var currentLocation:CLLocation!
  
  var tickerHandler = Event<HHMMSS>()
  var adviceChangedHandler = Event<Advice>()
  var stationChangedHandler = Event<[Station]>()
  var fromToChanged = Event<FromTo>()
  var locationUpdated = Event<CLLocation>()
  var userDefaultsDidChange = Event<Void>()
  
  var adviceDataUpdated = Event<Advice>()
  var adviceDataSubscription: EventSubscription<Advice>? = .None
  
  var locationManager:CLLocationManager
  var geofences:[CLRegion] = []
  
  var closeStations:[Station] = []
  var recentStations:[Station] = []
  
  var currentAdviceRequest:Request!
  
  class var sharedInstance: TreinTicker {
    if treinTickerSharedInstance == nil {
      treinTickerSharedInstance = TreinTicker(isExtention: false)
    }
    return treinTickerSharedInstance
  }
  
  class var sharedExtensionInstance: TreinTicker {
    if treinTickerShareExtensionInstance == nil {
      treinTickerShareExtensionInstance = TreinTicker(isExtention: true)
    }
    return treinTickerShareExtensionInstance
  }
  
  private init(isExtention:Bool) {
    self.isExtention = isExtention
    locationManager = CLLocationManager()
    super.init()
    
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    if stations.count > 0 {
      stationChangedHandler.notify(stations)
    }
    
    API().getStations { [weak self] stations in
      self?.setInitialState()
      self?.stations = stations
      self?.stationChangedHandler.notify(stations)
    }
    
    NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
      self.userDefaultsDidChange.notify()
      return
    }
    
    userDefaultsDidChange += { [weak self] _ in
      self?.fromToChanged.notify(FromTo(from: self?.from, to: self?.to))
    }
  }
  
  var currentAdivce:Advice? {
    set {
      if (UserDefaults.currentAdvice == newValue) {
        return
      }
      UserDefaults.currentAdvice = newValue
      let currentAdvice = newValue
      
      minuteTicker = 0
      for region in locationManager.monitoredRegions {
        if let r = region as? CLRegion {
          if let station = findStationByCode(CodeContainer.getFromString(r.identifier)) {
            locationManager.stopMonitoringForRegion(r)
          }
        }
      }
      var i = 0
      for deel in currentAdvice!.reisDeel {
        let target = deel.stops.last
        let station = stations.filter {
          $0.name.lang == target?.name
          }.first
        
        locationManager.startMonitoringForRegion(station?.getRegion(i))
        i++
      }
      
      if let currentAdvice = currentAdvice {
        dispatch_async(dispatch_get_main_queue()) {
          self.adviceChangedHandler.notify(currentAdvice)
        }
      }
    }
    get {
      return UserDefaults.currentAdvice
    }
  }
  
  private var adviceRequest:AdviceRequest? {
    didSet {
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
  
  private var _from:Station?
  var from:Station? {
    set {
      if let from = newValue {
        _from = from
        UserDefaults.from = from.code
        if (to != nil) {
          adviceRequest = AdviceRequest(from: from, to: to!)
          dispatch_async(dispatch_get_main_queue()) {
            self.fromToChanged.notify(FromTo(from: from, to: self.to))
            return
          }
        }
        MostUsed.addStation(from)
      }
    }
    get {
      if _from == nil || _from != UserDefaults.from {
        let newFrom = find(stations, UserDefaults.from) ?? stations.first
        _from = newFrom
        return newFrom
      } else {
        return _from
      }
    }
  }
  
  private var _to:Station?
  var to:Station? {
    set {
      if let to = newValue {
        _to = newValue
        UserDefaults.to = to.code
        if (from != nil) {
          adviceRequest = AdviceRequest(from: from!, to: to)
          dispatch_async(dispatch_get_main_queue()) {
            self.fromToChanged.notify(FromTo(from: self.from, to: to))
            return;
          }
        }
        
        MostUsed.addStation(to)
      }
    }
    get {
      if _to == nil || _to!.code != UserDefaults.to {
        let newTo = find(stations, UserDefaults.to) ?? stations.first
        _to = newTo
        return newTo
      } else {
        return _to
      }
    }
    
  }
  
  func setInitialState() {
    if from != nil && to != nil {
      adviceRequest = AdviceRequest(from: from!, to: to!)
      fromToChanged.notify(FromTo(from: self.from, to: to))
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
      self.fromToChanged.notify(FromTo(from: self.from, to: to))
    }
    if from != nil && to != nil {
      self.fromToChanged.notify(FromTo(from: self.from, to: to))
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
    
    if let adviceRequest = adviceRequest {
      currentAdviceRequest = API().getAdvice(adviceRequest) { advices in
        let a:Array<Advice> = advices;
        self.advices = a
        
        if let adv = self.getCurrentAdvice() {
          self.adviceDataUpdated.notify(adv)
        }
      }
    }
  }
  
  func getUpcomingAdvices() -> [Advice] {
    let advicesSorted = sorted(advices) { a,b in
      a.vertrek.actual.timeIntervalSince1970 < b.vertrek.actual.timeIntervalSince1970
    }
    
    return advicesSorted.filter {
        $0.vertrek.actual.timeIntervalSinceNow > 0
      }.filter {
        $0.status != .NietMogelijk
    }
  }
  
  func getUpcomingAdvicesWithOffset() -> [Advice] {
    return getUpcomingAdvices().filter{ $0.vertrek.planned.timeIntervalSince1970 >= self.adviceOffset?.timeIntervalSince1970 }
  }
  
  func getAdviceOffset() -> Int {
    if let c = currentAdivce {
      return indexOf(getUpcomingAdvices(), c)
    }
    return -1
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
    if (adviceRequest != nil) {
      if let currentAdv = getCurrentAdvice() {
        if let currentAdvice = self.currentAdivce {
          if (currentAdvice != currentAdv) {
            println("upcoming advices: \(getUpcomingAdvices().count)")
            self.currentAdivce = currentAdv
          }
        } else {
          self.currentAdivce = currentAdv
        }
        
        self.tickerHandler.notify(currentAdv.vertrek.actual.toMMSSFromNow())
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
      //to = originalFrom!
    }
  }
  
  var shouldUpdate:Bool = false
  
  func fromCurrentLocation() {
    shouldUpdate = true
    locationManager.startUpdatingLocation()
  }
  
}
