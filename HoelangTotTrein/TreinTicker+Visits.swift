//
//  TreinTicker+Visits.swift
//  
//
//  Created by Tomas Harkema on 05-03-15.
//
//

import UIKit
import CoreLocation

extension TreinTicker : CLLocationManagerDelegate {
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
      if let a = arrivedStation {
        fireArrivalNotification(a)
      }
      return;
    }
    
    updateAdvice {
      let notificationBody = $0.notificationPhrase(code.deelIndex+1)
      
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
    
    self.currentLocation = (locations.first)!.copy() as! CLLocation;
    
    let back: () -> Station? = {
      self.closeStations =  Station.sortStationsOnLocation(self.stations, loc: self.currentLocation!, number:10, sorter: <)
      let closest = Station.getClosestStation(self.stations, loc: self.currentLocation!)
      return closest
    }
    
    let main: Station? -> () = { closest in
      if let toOpt = self.to {
        if (closest == toOpt) {
          self.switchAdviceRequest()
        } else {
          self.from = closest
        }
      }
    }
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let result = back()
      dispatch_async(dispatch_get_main_queue()) {
        main(result)
        self.locationUpdated.notify(self.currentLocation)
      }
    }
    
  }
  
  func fireArrivalNotification(station:Station) {
//    let notificationBody = "Je bent aangekomen op \(station.name.lang) (duh). Voor je het vergeet: wel uitchecken hè? 😇"
//    let notification = UILocalNotification()
//    notification.alertBody = notificationBody
//    notification.fireDate = NSDate()
//    notification.soundName = UILocalNotificationDefaultSoundName
//    
//    NSNotificationCenter.defaultCenter().postNotificationName("showNotification", object: notification)
  }
  
}

