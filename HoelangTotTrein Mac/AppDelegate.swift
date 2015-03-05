//
//  AppDelegate.swift
//  HoelangTotTrein Mac
//
//  Created by Tomas Harkema on 04-03-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
    
    NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquitousKeyValueStoreDidChangeExternallyNotification, object: NSUbiquitousKeyValueStore.defaultStore(), queue: NSOperationQueue.mainQueue()) { (notification) in
      let ubiquitousKeyValueStore = notification.object as NSUbiquitousKeyValueStore
      ubiquitousKeyValueStore.synchronize()
      
      
      println("FROM: \(ubiquitousKeyValueStore.stringForKey(FromKey))")
    }
    
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }


}

