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
  
  @IBOutlet weak var advicesCollectionView: UICollectionView!
  @IBOutlet weak var headerView: UIView!
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
  
  var cellTimer:NSTimer?
  
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
    
    advicesCollectionView.delegate = self
    advicesCollectionView.dataSource = self
    advicesCollectionView.backgroundView = nil
    advicesCollectionView.backgroundColor = UIColor.clearColor()
    
    advicesIndicator.transform = CGAffineTransformMakeRotation(CGFloat(M_PI * 90.0/180))
    
    TreinTicker.sharedInstance.adviceChangedHandler = { [weak self] (advice) in
      self?.advicesCollectionView.reloadData()
      return;
    }
    
    TreinTicker.sharedInstance.fromToChanged = { [weak self] from, to in
      self?.toButton.setTitle(to?.name.lang, forState: UIControlState.Normal)
      self?.fromButton.setTitle(from?.name.lang, forState: UIControlState.Normal)
      self?.selectRow()
      self?.advicesCollectionView.reloadData()
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    TreinTicker.sharedInstance.start()
    
    headerView.updateConstraints()
    
    let effect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
    let blurView = UIVisualEffectView(effect: effect)
    blurView.frame = headerView.frame
    headerView.backgroundColor = UIColor.clearColor()
    headerView.addSubview(blurView)
    headerView.sendSubviewToBack(blurView)
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
