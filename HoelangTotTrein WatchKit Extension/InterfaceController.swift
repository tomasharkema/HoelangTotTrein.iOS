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

class InterfaceController: WKInterfaceController {
  
  @IBOutlet weak var timer: WKInterfaceTimer!
  
  @IBOutlet weak var fromButton: WKInterfaceButton!
  @IBOutlet weak var toButton: WKInterfaceButton!
  @IBOutlet weak var spoorLabel: WKInterfaceLabel!
  @IBOutlet weak var vertragingsLabel: WKInterfaceLabel!
  
  var time:NSDate?
  
  let treinTicker = TreinTicker.sharedExtensionInstance
  
  override func awakeWithContext(context: AnyObject?) {
    treinTicker.fromCurrentLocation()
    // Configure interface objects here.
    
    treinTicker.adviceChangedHandler += { [weak self] _ in
      self?.updateUI()
      return;
    }
    
    treinTicker.tickerHandler += { [weak self] time in
      
      if self?.time != time.date {
        self?.time = time.date
        self?.updateUI()
      }
    
    }
    
    treinTicker.fromToChanged += { _ in
      self.updateUI()
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
      self.timer.setTextColor(t.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor())
      timer.start()
    }
    
    fromButton.setTitle((treinTicker.from?.name.lang ?? "" ) + "\n" + treinTicker.currentAdivce!.vertrek.getFormattedString() ?? "")
    toButton.setTitle((treinTicker.to?.name.lang ?? "") + "\n" + treinTicker.currentAdivce!.aankomst.getFormattedString() ?? "")
    
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
    super.didDeactivate()
  }
  
  
}
