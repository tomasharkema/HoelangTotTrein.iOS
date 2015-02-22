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
  
  weak var pickerController:PickerViewController?
  
  @IBOutlet weak var mainView: UIView!
  
  
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    pickerContainer.hidden = true
    
    TreinTicker.sharedInstance.tickerHandler = { [weak self] time in
      let timeToGoLabel = time.string()
      self?.timeToGoLabel.text = timeToGoLabel
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
  
  override func viewDidDisappear(animated: Bool) {
    TreinTicker.sharedInstance.stop()
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
  
  func showPicker() {
    TreinTicker.sharedInstance.stop()
    
    let image = mainView.screenShot()
    
    if let picker = pickerController {
      picker.backdrop = image
      picker.setState(true, completion: nil)
      picker.mode = selectionState
      picker.currentStation = (selectionState == .From) ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to
      pickerContainer.hidden = false
    }
  }
  
  func hidePicker() {
    if let picker = pickerController {
      picker.setState(false) {
        if $0 {
          self.pickerContainer.hidden = true
        }
      }
      TreinTicker.sharedInstance.start()
    }
  }
  
  @IBAction func fromButton(sender: AnyObject) {
    selectionState = .From
    
    showPicker()
  }
  
  @IBAction func toButton(sender: AnyObject) {
    selectionState = .To
    
    showPicker()
  }
  
  @IBAction func locButton(sender: AnyObject) {
    TreinTicker.sharedInstance.fromCurrentLocation()
  }
  
  @IBAction func swapLocations(sender: AnyObject) {
    TreinTicker.sharedInstance.switchAdviceRequest()
    TreinTicker.sharedInstance.saveOriginalFrom()
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "picker" {
      let picker:PickerViewController = segue.destinationViewController as PickerViewController
      picker.mode = selectionState
      picker.currentStation = (selectionState == .From) ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to
      picker.selectStationHandler = { [weak self] station in
        self?.pick(station)
        self?.hidePicker()
      }
      self.pickerController = picker
    }
  }
}
