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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let treinTicker = TreinTicker.sharedExtensionInstance
    
    treinTicker.tickerHandler = { [weak self] time in
      self?.updateUI()
      return;
    }
    
    treinTicker.adviceChangedHandler = { [weak self] (advice) in
      self?.updateUI()
      return;
    }
    
    treinTicker.fromToChanged = { [weak self] from, to in
      self?.updateUI()
      return;
    }
    
    treinTicker.start()
    
    //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateUI"), name: NSUserDefaultsDidChangeNotification, object: nil)
    
  }
  
  func updateUI() {
    let treinTicker = TreinTicker.sharedExtensionInstance
    
      self.timeLabel.text = treinTicker.currentAdivce.vertrek.actual.toMMSSFromNow().string()
      UIView.animateWithDuration(1.0) {
        self.timeLabel.textColor = treinTicker.currentAdivce.vertrek.actual.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor()
    }
    
    self.fromLabel.text = TreinTicker.sharedExtensionInstance.from?.name.lang ?? ""
    self.toLabel.text = TreinTicker.sharedExtensionInstance.to?.name.lang ?? ""
    
    if let ad = treinTicker.currentAdivce {
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
    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
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
