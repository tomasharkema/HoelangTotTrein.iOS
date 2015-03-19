//
//  MapController.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 15-03-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation

class MapController : WKInterfaceController, CLLocationManagerDelegate {
  
  @IBOutlet weak var map: WKInterfaceMap!
  
  let locationManager = CLLocationManager()
  
  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)
    locationManager.requestWhenInUseAuthorization()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.startUpdatingLocation()
    
  }
  
  override func willActivate() {
    super.willActivate()
    let from = TreinTicker.sharedExtensionInstance.from?.getLocation()
  }
  
  func regionForLocations(locations:[CLLocationCoordinate2D]) -> MKCoordinateRegion {
    var minLat = 90.0
    var maxLat = -90.0
    var minLong = 180.0
    var maxLong = -180.0
    
    for location in locations {
      if location.latitude < minLat {minLat = location.latitude}
      if location.latitude > maxLat {maxLat = location.latitude}
      if location.longitude < minLong {minLong = location.longitude}
      if location.longitude > maxLong {maxLong = location.longitude}
    }
    
    minLat = minLat - 0.001
    maxLat = maxLat + 0.001
    minLong = minLong - 0.001
    maxLong = maxLong + 0.001
    
    let center = CLLocationCoordinate2DMake((minLat + maxLat) / 2.0, (minLong + maxLong) / 2.0)
    let span = MKCoordinateSpanMake(maxLat - minLat, maxLong - minLong)
    let region = MKCoordinateRegionMake(center, span)

    return region
  }
  
  func updateUI(location: CLLocation) {
//    map.removeAllAnnotations()
    
    let currentLocation = location.coordinate
    if let travelToLocation = TreinTicker.sharedExtensionInstance.from?.getLocation().coordinate {
    
      let rect = regionForLocations([currentLocation, travelToLocation])
      
      map.setRegion(rect)
      map.addAnnotation(currentLocation, withPinColor: .Green)
      map.addAnnotation(travelToLocation, withPinColor: .Red)
    }
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    let location = locations.first as CLLocation
    
    updateUI(location)
    
    locationManager.stopUpdatingLocation()
  }
  
}