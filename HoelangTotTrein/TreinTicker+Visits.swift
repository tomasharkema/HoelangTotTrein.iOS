//
//  TreinTicker+Visits.swift
//  
//
//  Created by Tomas Harkema on 05-03-15.
//
//

import UIKit
import CoreLocation

enum NotificationType: String {
  case Overstappen = "overstappen"
  case Uitstappen = "uitstappen"
}

extension TreinTicker : CLLocationManagerDelegate {
  
  func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
    println("ERROR! \(error.description)")
  }
  
  func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
    locationManager.stopMonitoringForRegion(region)
    let code = CodeContainer.getFromString(region.identifier)
    let arrivedStation = findStationByCode(code)
    
    if (currentAdivce?.reisDeel.count <= (code.deelIndex + 1)) {
      // final destination
      switchAdviceRequestOriginal()
      originalFrom = to
      if let a = arrivedStation {
        fireArrivalNotification(a)
      }
      return;
    }
    
    adviceDataSubscription = adviceDataUpdated.add {
      let notificationBody = $0.notificationPhrase(code.deelIndex+1)
      
      let notification = UILocalNotification()
      notification.alertBody = notificationBody
      notification.fireDate = NSDate()
      notification.soundName = UILocalNotificationDefaultSoundName
      notification.userInfo = $0.notificationUserInfo(code.deelIndex+1)
      notification.alertTitle = "Overstappen"
      
      NSNotificationCenter.defaultCenter().postNotificationName("showNotification", object: notification)
      
      self.adviceDataSubscription?.invalidate()
    }
    
    from = arrivedStation
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
    let notificationBody = "Stap uit op station \(station.name.lang)"
    let userInfo = ["type": NotificationType.Uitstappen.rawValue]
    let notification = UILocalNotification()
    notification.alertBody = notificationBody
    notification.fireDate = NSDate()
    notification.userInfo = userInfo
    notification.soundName = UILocalNotificationDefaultSoundName
    notification.alertTitle = "Uitstappen"
    
    NSNotificationCenter.defaultCenter().postNotificationName("showNotification", object: notification)
  }
  
}

