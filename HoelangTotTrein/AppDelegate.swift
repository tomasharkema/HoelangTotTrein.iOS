//
//  AppDelegate.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 11-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    NewRelic.startWithApplicationToken("AA37eca143a6cbc43c025498e41838d785d5666a06")
    
    // Override point for customization after application launch
    application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Sound | .Alert | .Badge, categories: nil))
    
    NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquitousKeyValueStoreDidChangeExternallyNotification, object: NSUbiquitousKeyValueStore.defaultStore(), queue: NSOperationQueue.mainQueue()) { (notification) in
      let ubiquitousKeyValueStore = notification.object as! NSUbiquitousKeyValueStore
      ubiquitousKeyValueStore.synchronize()
      println("FROM: \(ubiquitousKeyValueStore.objectForKey(FromKey))")
      
      println("TO: \(ubiquitousKeyValueStore.objectForKey(ToKey))")
    }
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showNotification:"), name: "showNotification", object: nil)
    let lastOpened = UserDefaults.lastOpened
    
    TreinTicker.sharedInstance.fromCurrentLocation()
    
    UserDefaults.lastOpened = NSDate()
    return true
  }

  func applicationWillResignActive(application: UIApplication) {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    UserDefaults.synchronize()
    CloudUserService.synchronize()
    TreinTicker.sharedInstance.stop()
  }

  func applicationDidEnterBackground(application: UIApplication) {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    UserDefaults.synchronize()
    CloudUserService.synchronize()
    TreinTicker.sharedInstance.stop()
  }

  func applicationWillEnterForeground(application: UIApplication) {
      // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    TreinTicker.sharedInstance.start()
  }

  func applicationDidBecomeActive(application: UIApplication) {
      // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    TreinTicker.sharedInstance.start()
  }

  func applicationWillTerminate(application: UIApplication) {
      // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    UserDefaults.synchronize()
    CloudUserService.synchronize()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: "showNotification", object: nil)
  }

  func showNotification(notification:NSNotification) {
    if let not = notification.object as? UILocalNotification {
      UIApplication.sharedApplication().presentLocalNotificationNow(not)
    }
  }
  
  func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]!) -> Void) -> Bool {
    println(userActivity)
    if let window = self.window {
      window.rootViewController?.restoreUserActivityState(userActivity)
    }
    return true
  }
}

