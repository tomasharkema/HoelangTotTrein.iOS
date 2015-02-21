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
  
  var time:HHMMSS?
  
  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)
    // Configure interface objects here.
  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    let treinTicker = TreinTicker.sharedExtensionInstance
    
    treinTicker.tickerHandler = { [weak self] time in
      self?.time = time
      self?.updateUI()
    }
    
    treinTicker.adviceChangedHandler = { [weak self] (advice) in
      println()
      self?.updateUI()
    }
    
    treinTicker.fromToChanged = { [weak self] from, to in
      println()
      self?.updateUI()
    }
    
    treinTicker.start()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userDefaultsDidChange:"), name:NSUserDefaultsDidChangeNotification, object: nil)
    
    super.willActivate()
  }
  
  func updateUI() {
    if let t = time {
      self.timer.setDate(t.date)
    }
    
    fromLabel.setText(TreinTicker.sharedExtensionInstance.from?.name.lang ?? "")
    toLabel.setText(TreinTicker.sharedExtensionInstance.to?.name.lang ?? "")
  }
  
  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    TreinTicker.sharedExtensionInstance.stop()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    super.didDeactivate()
  }
  
  func userDefaultsDidChange(notification:NSNotification) {
    updateUI()
  }
  
}
