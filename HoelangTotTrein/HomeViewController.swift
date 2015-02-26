//
//  HomeViewController.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 11-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

enum StationType {
  case From
  case To
}

class HomeViewController: UIViewController {
  
  @IBOutlet weak var timeToGoLabel: UILabel!
  @IBOutlet weak var vertagingLabel: UILabel!
  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!
  
  @IBOutlet weak var fromStationLabel: UILabel!
  @IBOutlet weak var toStationLabel: UILabel!
  
  @IBOutlet weak var spoorLabel: UILabel!
  @IBOutlet weak var legPhraseLeftTextView: UITextView!
  @IBOutlet weak var legPhraseRightTextView: UITextView!
  @IBOutlet weak var alertTextView: UITextView!
  @IBOutlet weak var pickerContainer: UIView!
  @IBOutlet weak var skipButton: UIButton!
  
  @IBOutlet weak var mainView: UIView!
  
  @IBOutlet weak var advicesIndicator: UIPageControl!
  
  private var selectionState:StationType = .From {
    didSet {
      if let i:Int = find(TreinTicker.sharedInstance.stations, selectionState == .From ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to) {
        let station:Station = TreinTicker.sharedInstance.stations[i]
        self.pick(station)
        selectRow()
      }
    }
  }
  
  private func selectRow() {
    if let i = find(TreinTicker.sharedInstance.stations, selectionState == .From ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to!) {
      //stationPicker.selectRow(i, inComponent: 0, animated: true)
    }
  }
  
  deinit {
    println("deinit")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    advicesIndicator.transform = CGAffineTransformMakeRotation(CGFloat(M_PI * 90.0/180))
    
    TreinTicker.sharedInstance.tickerHandler = { [weak self] time in
      let timeToGoLabel = time.string()
      self?.timeToGoLabel.text = timeToGoLabel
      UIView.animateWithDuration(1.0) {
        self?.timeToGoLabel.textColor = time.date.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor()
        return;
      }
      
      self?.updateAdviceIndicator()
    };
    
    TreinTicker.sharedInstance.adviceChangedHandler = { [weak self] (advice) in
      let from = advice.adviceRequest.from.name.lang
      let to = advice.adviceRequest.to.name.lang
      let fromTime = advice.vertrek.getFormattedString()
      let toTime = advice.aankomst.getFormattedString()
      
      self?.fromStationLabel.text = "\(from) - \(fromTime)"
      self?.toStationLabel.text = "\(to) - \(toTime)"
      self?.spoorLabel.text = advice.firstStop()?.spoor ?? "Spoor onbekend"
      self?.legPhraseLeftTextView.text = advice.legPhraseLeft()
      self?.legPhraseLeftTextView.textColor = UIColor.secundairGreyColor()
      self?.legPhraseLeftTextView.textAlignment = NSTextAlignment.Right
      
      self?.legPhraseRightTextView.text = advice.legPhraseRight()
      self?.legPhraseRightTextView.textColor = UIColor.secundairGreyColor()
      self?.legPhraseRightTextView.textAlignment = NSTextAlignment.Left
      
      if let melding = advice.melding {
        self?.alertTextView.text = melding.text
        self?.alertTextView.hidden = false
      } else {
        self?.alertTextView.insertText("")
        self?.alertTextView.hidden = true
      }
      
      if let vertraging = advice.vertrekVertraging {
        self?.vertagingLabel.text = vertraging
        self?.vertagingLabel.hidden = false
      } else {
        self?.vertagingLabel.hidden = true
      }
    }
    
    TreinTicker.sharedInstance.fromToChanged = { [weak self] from, to in
      self?.toButton.setTitle(to?.name.lang, forState: UIControlState.Normal)
      self?.fromButton.setTitle(from?.name.lang, forState: UIControlState.Normal)
      self?.selectRow()
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    TreinTicker.sharedInstance.start()
  }
  
  func pick(station:Station) {
    pick(station, state: selectionState)
  }
  
  func pick(station:Station, state:StationType) {
    if state == .From {
      TreinTicker.sharedInstance.from = station
    } else {
      TreinTicker.sharedInstance.to = station
    }
  }
  
  func updateAdviceIndicator() {
    let adviceOffset = indexOf(TreinTicker.sharedInstance.getUpcomingAdvices(), TreinTicker.sharedInstance.currentAdivce)
    advicesIndicator.currentPage = adviceOffset
    
    let numberOfAdvices = TreinTicker.sharedInstance.getUpcomingAdvices().count
    advicesIndicator.numberOfPages = numberOfAdvices
    
    advicesIndicator.hidden = numberOfAdvices <= 1
    skipButton.hidden = numberOfAdvices <= 1
  }
  
  @IBAction func fromButton(sender: AnyObject) {
    selectionState = .From
    
    performSegueWithIdentifier("picker", sender: self)
  }
  
  @IBAction func toButton(sender: AnyObject) {
    selectionState = .To
    performSegueWithIdentifier("picker", sender: self)
  }
  
  @IBAction func locButton(sender: AnyObject) {
    TreinTicker.sharedInstance.fromCurrentLocation()
  }
  
  @IBAction func swapLocations(sender: AnyObject) {
    TreinTicker.sharedInstance.switchAdviceRequest()
    TreinTicker.sharedInstance.saveOriginalFrom()
  }
  
  @IBAction func skipAdvice(sender: AnyObject) {
    TreinTicker.sharedInstance.skipCurrentAdvice()
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "picker" {
      let picker:PickerViewController = segue.destinationViewController as PickerViewController
      
      let image = mainView.screenShot()
      
      picker.backdrop = image
      picker.mode = selectionState
      picker.currentStation = (selectionState == .From) ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to
      picker.selectStationHandler = { [weak self] station in
        self?.pick(station)
        return;
      }
    }
  }
  
  override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
    let unwindSegue = UnwindPickerSegue()
    
    return unwindSegue;
  }
}
