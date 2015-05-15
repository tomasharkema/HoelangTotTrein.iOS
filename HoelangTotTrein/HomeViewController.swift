//
//  HomeViewController.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 11-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import Observable

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
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var mainView: UIView!
  
  @IBOutlet weak var advicesIndicator: UIPageControl!
  
  var headerBlurView: UIVisualEffectView?
  var collectionBlurView: UIVisualEffectView?
  @IBOutlet weak var backgroundView: UIImageView!
  
  var cellTimer:NSTimer?
  
  private var selectionState:StationType = .From {
    didSet {
      if let i:Int = find(TreinTicker.sharedInstance.stations, selectionState == .From ? TreinTicker.sharedInstance.from! : TreinTicker.sharedInstance.to!) {
        let station:Station = TreinTicker.sharedInstance.stations[i]
        self.pick(station)
        selectRow()
      }
    }
  }
  
  private func selectRow() {
    if let i = find(TreinTicker.sharedInstance.stations, selectionState == .From ? TreinTicker.sharedInstance.from! : TreinTicker.sharedInstance.to!) {
      //stationPicker.selectRow(i, inComponent: 0, animated: true)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    advicesCollectionView.delegate = self
    advicesCollectionView.dataSource = self
    advicesCollectionView.backgroundView = nil
    advicesCollectionView.backgroundColor = UIColor.clearColor()
    
    advicesIndicator.transform = CGAffineTransformMakeRotation(CGFloat(M_PI * 90.0/180))
    
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
    
    fromButton.titleLabel?.adjustsFontSizeToFitWidth = true
    toButton.titleLabel?.adjustsFontSizeToFitWidth = true

    TreinTicker.sharedInstance.adviceChangedHandler += { [weak self] _ in
      self?.reload()
      return;
    }
    
    TreinTicker.sharedInstance.fromToChanged += { [weak self] fromTo in
      let from = fromTo.from
      let to = fromTo.to
      
      self?.toButton.setTitle(to?.name.lang, forState: UIControlState.Normal)
      self?.fromButton.setTitle(from?.name.lang, forState: UIControlState.Normal)
      self?.reload()
      return;
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    TreinTicker.sharedInstance.start()
    
    if headerBlurView == nil {
//      let effect = UIBlurEffect(style: .Light)
//      let blurView = UIVisualEffectView(effect: effect)
//      var frame = headerView.frame
//      frame.size.width = view.frame.width
//      blurView.frame = frame
      
//      headerView.backgroundColor = UIColor.clearColor()
//      headerView.addSubview(blurView)
//      headerView.sendSubviewToBack(blurView)
      
      //self.headerBlurView = blurView
    }
    
    if collectionBlurView == nil {
      let darkEffect = UIBlurEffect(style: .Dark)
    }
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      TreinTicker.sharedInstance.switchAdviceRequest()
      TreinTicker.sharedInstance.saveOriginalFrom()
    }
  }
  
  @IBAction func pageControllerTouched(sender: AnyObject) {
    advicesCollectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: (sender as! UIPageControl).currentPage, inSection: 0), atScrollPosition: .CenteredVertically, animated: true)
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "picker" {
      let picker:PickerViewController = segue.destinationViewController as! PickerViewController
      
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
