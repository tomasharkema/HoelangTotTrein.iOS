//
//  InterfaceController.swift
//  HoelangTotTrein WatchKit Extension
//
//  Created by Tomas Harkema on 21-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation
import Observable

class InterfaceController: WKInterfaceController, NSUserActivityDelegate {
  
  @IBOutlet weak var timer: WKInterfaceTimer!
  
  @IBOutlet weak var fromButton: WKInterfaceButton!
  @IBOutlet weak var toButton: WKInterfaceButton!
  @IBOutlet weak var spoorLabel: WKInterfaceLabel!
  @IBOutlet weak var vertragingsLabel: WKInterfaceLabel!
  
  var adviceSub:EventSubscription<Advice>?
  var tickerSub:EventSubscription<HHMMSS>?
  var fromToSub:EventSubscription<FromTo>?
  
  var time:NSDate?
  
  let treinTicker = TreinTicker.sharedInstance
  
  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)
  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    
    treinTicker.fromCurrentLocation()
    
    adviceSub = treinTicker.adviceChangedHandler += { [weak self] _ in
      self?.updateUI()
      println("adviceChangedHandler")
      self?.updateUserActivity("nl.tomasharkema.HoelangTotTrein.view", userInfo: ["":""], webpageURL: self?.treinTicker.currentAdivce?.getNTUrl())
    }
    
    tickerSub = treinTicker.tickerHandler += { [weak self] time in
      if self?.time != time.date {
        self?.time = time.date
        self?.updateUI()
        println("tickerHandler and Update")
      }
      
      println("tickerHandler")
    }
    
    fromToSub = treinTicker.fromToChanged += { _ in
      self.updateUI()
      println("fromToChanged")
    }
    
    treinTicker.start()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userDefaultsDidChange"), name:NSUserDefaultsDidChangeNotification, object: nil)
    
    updateUserActivity("nl.tomasharkema.HoelangTotTrein.view", userInfo: ["":""], webpageURL: NSURL(scheme: "http", host: "9292.nl", path: "/"))
    
    super.willActivate()
  }
  
  func userDefaultsDidChange() {
    println("userDefaultsDidChange")
    updateUI()
  }
  
  func updateUI() {
    if let t = time {
      timer.setDate(t)
      self.timer.setTextColor(t.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor())
      timer.start()
    }
    
    if let currentAdvice = treinTicker.currentAdivce {
      fromButton.setTitle((treinTicker.from?.name.lang ?? "" ) + " " + currentAdvice.vertrek.getFormattedString() ?? "")
      toButton.setTitle((treinTicker.to?.name.lang ?? "") + " " + currentAdvice.aankomst.getFormattedString() ?? "")
    }
    
    if let spoor = treinTicker.currentAdivce?.fromPlatform {
      spoorLabel.setText("spoor \(spoor)")
    } else {
      spoorLabel.setText("")
    }
    
    vertragingsLabel.setText(treinTicker.currentAdivce?.vertrekVertraging ?? "")
  }
  
  @IBAction func fromTapped() {
    treinTicker.bumpFrom()
  }
  
  @IBAction func toTapped() {
    treinTicker.bumpTo()
  }
  
  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    treinTicker.stop()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    
    adviceSub?.invalidate()
    tickerSub?.invalidate()
    fromToSub?.invalidate()
    
    invalidateUserActivity()
    
    super.didDeactivate()
  }
  func userActivityWasContinued(userActivity: NSUserActivity) {
    println("YAY")
  }
}
