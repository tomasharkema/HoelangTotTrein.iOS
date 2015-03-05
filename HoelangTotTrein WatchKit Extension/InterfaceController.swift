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
  
  var time:NSDate?
  
  let treinTicker = TreinTicker.sharedExtensionInstance
  
  override func awakeWithContext(context: AnyObject?) {
    treinTicker.fromCurrentLocation()
    // Configure interface objects here.
    
    treinTicker.adviceChangedHandler = { [weak self] (advice) in
      self?.updateUI()
      return;
    }
    
    treinTicker.tickerHandler = { [weak self] time in
      if self?.time != time.date {
        self?.time = time.date
        self?.updateUI()
      }
    }
    
    treinTicker.fromToChanged = { [weak self] from, to in
      self?.updateUI()
      return;
    }
    
    super.awakeWithContext(context)
  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    
    treinTicker.start()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateUI"), name:NSUserDefaultsDidChangeNotification, object: nil)
    
    super.willActivate()
  }
  
  func userDefaultsDidChange() {
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
    fromButton.setTitle((treinTicker.from?.name.lang ?? "" ) + " " + treinTicker.currentAdivce.vertrek.getFormattedString())
    toButton.setTitle((treinTicker.to?.name.lang ?? "") + " " + treinTicker.currentAdivce.aankomst.getFormattedString())
  }
  
  @IBAction func fromTapped() {
    treinTicker.bumpFrom()
    updateUI()
  }
  
  @IBAction func toTapped() {
    treinTicker.bumpTo()
    updateUI()
  }
  
  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    treinTicker.stop()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    super.didDeactivate()
  }
  
}
