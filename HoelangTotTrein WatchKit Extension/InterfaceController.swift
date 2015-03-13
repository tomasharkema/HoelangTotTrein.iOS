//
//  InterfaceController.swift
//  HoelangTotTrein WatchKit Extension
//
//  Created by Tomas Harkema on 21-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
  
  @IBOutlet weak var timer: WKInterfaceTimer!
  
  @IBOutlet weak var fromButton: WKInterfaceButton!
  @IBOutlet weak var toButton: WKInterfaceButton!
  @IBOutlet weak var spoorLabel: WKInterfaceLabel!
  
  var time:NSDate?
  
  let treinTicker = TreinTicker.sharedExtensionInstance
  
  override func awakeWithContext(context: AnyObject?) {
    treinTicker.fromCurrentLocation()
    // Configure interface objects here.
    
    treinTicker.adviceChangedHandler = { [weak self] (advice) in
      println()
      self?.updateUI()
    }
    
    treinTicker.tickerHandler = { [weak self] time in
      if self?.time != time.date {
        self?.time = time.date
        println("setNewTime")
        self?.updateUI()
      }
    }
    
    treinTicker.fromToChanged = { [weak self] _ in
      println("fromToChanged")
      self?.updateUI()
    }
    
    super.awakeWithContext(context)
  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    
    treinTicker.start()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userDefaultsDidChange"), name:NSUserDefaultsDidChangeNotification, object: nil)
    
    super.willActivate()
  }
  
  func userDefaultsDidChange() {
    println("userDefaultsDidChange")
    NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: false)
  }
  
  func updateUI() {
    if let t = time {
      timer.setDate(t)
      UIView.animateWithDuration(1.0) {
        self.timer.setTextColor(t.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor())
      }
      timer.start()
    }
    fromButton.setTitle((treinTicker.from?.name.lang ?? "" ) + " - " + treinTicker.currentAdivce.vertrek.getFormattedString())
    toButton.setTitle((treinTicker.to?.name.lang ?? "") + " - " + treinTicker.currentAdivce.aankomst.getFormattedString())
    spoorLabel.setText(treinTicker.currentAdivce.fromPlatform ?? "")
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
    super.didDeactivate()
  }
  
}
