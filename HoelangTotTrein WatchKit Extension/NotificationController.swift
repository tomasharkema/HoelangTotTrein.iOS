//
//  NotificationController.swift
//  HoelangTotTrein WatchKit Extension
//
//  Created by Tomas Harkema on 21-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation


class NotificationController: WKUserNotificationInterfaceController {

  @IBOutlet weak var timeLabel: WKInterfaceTimer!
  
  @IBOutlet weak var spoorLabel: WKInterfaceLabel!
  
  @IBOutlet weak var vertragingLabel: WKInterfaceLabel!
  @IBOutlet weak var toLabel: WKInterfaceLabel!
  
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
        println("didReceiveLocalNotification")
      
      if let userInfo = localNotification.userInfo, type = NotificationType(rawValue: userInfo["type"] as? String ?? "") {
        
        switch type {
        case .Uitstappen:
          completionHandler(.Default)
        case .Overstappen:
          let date = userInfo["date"] as? NSDate
          
          timeLabel.setDate(date ?? NSDate())
          timeLabel.start()
          
          toLabel.setText("-> " + (userInfo["to"] as? String ?? ""))
          spoorLabel.setText("spoor " + (userInfo["spoor"] as? String ?? ""))
          vertragingLabel.setText(userInfo["vertraging"] as? String ?? "")
          
          setTitle("Overstappen")
          
          updateUserActivity("nl.tomasharkema.HoelangTotTrein.view", userInfo: ["":""], webpageURL: NSURL(scheme: "http", host: "9292.nl", path: "/"))
          
          completionHandler(.Custom)
        }
        
      } else {
        completionHandler(.Default)
      }
    }
  
    /*
    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
        // This method is called when a remote notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        completionHandler(.Custom)
    }
    */
}
