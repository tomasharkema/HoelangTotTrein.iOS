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
  
  @IBOutlet weak var fromLabel: WKInterfaceLabel!
  @IBOutlet weak var timer: WKInterfaceTimer!
  @IBOutlet weak var toLabel: WKInterfaceLabel!
  @IBOutlet weak var fromTime: WKInterfaceLabel!
  @IBOutlet weak var toTime: WKInterfaceLabel!
  
  var time:NSDate?
  
  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)
    // Configure interface objects here.
  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    let treinTicker = TreinTicker.sharedExtensionInstance
    
    treinTicker.adviceChangedHandler = { [weak self] (advice) in
      println()
      self?.updateUI()
    }
    
    treinTicker.tickerHandler = { [weak self] time in
      if self?.time != time.date {
        self?.time = time.date
        self?.updateUI()
      }
    }
    
    treinTicker.fromToChanged = { [weak self] from, to in
      println()
      self?.updateUI()
    }
    
    treinTicker.start()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userDefaultsDidChange"), name:NSUserDefaultsDidChangeNotification, object: nil)
    
    super.willActivate()
  }
  
  func userDefaultsDidChange() {
    println("userDefaultsDidChange")
    NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: false)
  }
  
  func updateUI() {
    let treinTicker = TreinTicker.sharedExtensionInstance
    if let t = time {
      timer.setDate(t)
      UIView.animateWithDuration(1.0) {
        self.timer.setTextColor(t.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor())
      }
      timer.start()
    }
    fromLabel.setText(treinTicker.from?.name.lang ?? "")
    toLabel.setText(treinTicker.to?.name.lang ?? "")
    fromTime.setText(treinTicker.currentAdivce.vertrek.getFormattedString() + (treinTicker.currentAdivce.vertrekVertraging ?? ""))
    toTime.setText(treinTicker.currentAdivce.aankomst.getFormattedString())
  }
  
  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    TreinTicker.sharedExtensionInstance.stop()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    super.didDeactivate()
  }
  
}
