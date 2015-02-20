//
//  TodayViewController.swift
//  Widget
//
//  Created by Tomas Harkema on 19-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
  @IBOutlet weak var fromLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var toLabel: UILabel!
  @IBOutlet weak var vertagingLabel: UILabel!
  @IBOutlet weak var spoorLabel: UILabel!
  
  var from:Station?
  var to:Station?
  var advice:Advice?
  var time:HHMMSS?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let treinTicker = TreinTicker.sharedExtensionInstance
    
    treinTicker.tickerHandler = { [weak self] time in
      println()
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
    
    NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
      self.updateUI()
    }
  }
  
  func updateUI() {
    if let t = time {
      self.timeLabel.text = t.string()
    }
    
    self.fromLabel.text = TreinTicker.sharedExtensionInstance.from?.name.lang ?? ""
    self.toLabel.text = TreinTicker.sharedExtensionInstance.to?.name.lang ?? ""
    
    if let ad = TreinTicker.sharedExtensionInstance.currentAdivce {
      self.spoorLabel.text = ad.firstStop()?.spoor
      if let vertraging = ad.vertrekVertraging {
        self.vertagingLabel.text = vertraging
        self.vertagingLabel.hidden = false
      } else {
        self.vertagingLabel.hidden = true
      }
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUI()
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    println("viewDidDisappear")
    TreinTicker.sharedExtensionInstance.stop()
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  @IBAction func goToAppButton(sender: AnyObject) {
    let url = NSURL(string: "hltt://home")
    self.extensionContext?.openURL(url!, completionHandler: nil)
  }
  
  func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
    // Perform any setup necessary in order to update the view.

    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData
    
    completionHandler(NCUpdateResult.NewData)
  }
  
  func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsetsZero
  }
    
}
