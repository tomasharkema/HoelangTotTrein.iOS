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
    
    self.currentLocation = (locations.first as CLLocation).copy() as CLLocation
    println(currentLocation)
    
    self.closeStations =  Station.sortStationsOnLocation(stations, loc: currentLocation!, sorter: <, number:5)
    
    let closest = Station.getClosestStation(stations, loc: currentLocation!)
    
    if let toOpt = to {
      if (closest! == toOpt) {
        switchAdviceRequest()
      } else {
        from = closest
      }
    }
  }
  
  func locationManager(manager: CLLocationManager!, didVisit visit: CLVisit!) {
    println(visit)
  }
  
  func fireArrivalNotification(station:Station) {
    let notificationBody = "Je bent aangekomen op \(station.name.lang) (duh). Voor je het vergeet: wel uitchecken hè? 😇"
    let notification = UILocalNotification()
    notification.alertBody = notificationBody
    notification.fireDate = NSDate()
    notification.soundName = UILocalNotificationDefaultSoundName
    
    NSNotificationCenter.defaultCenter().postNotificationName("showNotification", object: notification)
  }
  
}

