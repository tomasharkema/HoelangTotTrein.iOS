//
//  PickerViewController.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 15-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreLocation

typealias SelectStationHandler = (Station) -> Void

let PickerAnimationDuration = 0.5

class PickerViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var pickerTitle: UILabel!
  @IBOutlet weak var searchView: UITextField!
  
  @IBOutlet weak var leftMarginSearchField: NSLayoutConstraint!
  
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var pulldownIcon: UIImageView!
  
  
  var screenshotImageView:UIImageView!
  var backdropImageView:UIImageView!
  var backdrop: UIImage?
  
  var willDismiss:Bool = false
  var isDismissing:Bool = false
  
  var mode:StationType! {
    didSet {
      pickerTitle?.text = (mode == StationType.From) ? "Van" : "Naar"
    }
  }
  
  var currentStation:Station! {
    didSet {
      reload()
    }
  }
  
  var selectStationHandler:SelectStationHandler!
  
  var mostUsed:Array<Station> = []
  var stations:Array<Station> = []
  
  func reload() {
    self.mostUsed = MostUsed.getListByVisited().slice(5)
    stations = TreinTicker.sharedInstance.stations.filter { [weak self] station in
      return (self?.mostUsed.contains(station) != nil)
    }
    
    if let tv = tableView {
      tv.reloadData()
      selectRow()
    }
  }
  
  /// MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.backgroundColor = UIColor.clearColor()
    tableView.backgroundView = nil
    tableView.delegate = self
    tableView.dataSource = self
    
    backdropImageView = UIImageView(frame: view.bounds)
    view.insertSubview(backdropImageView, belowSubview: headerView)
    screenshotImageView = UIImageView(frame: view.bounds)
    view.insertSubview(screenshotImageView, belowSubview: backdropImageView)
    // set inital state
    backdropImageView.image = backdrop
    
    pickerTitle.text = (mode == StationType.From) ? "Van" : "Naar"
    
    searchView.delegate = self
    searchView.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)
    searchView.attributedPlaceholder = NSAttributedString(string: "Zoeken...", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.3)])
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    reload()
    animateMenu(true, animated: true, completion: nil)
  }
  
  /// MARK: Show State Animations
  
  var showState:Bool = false
  
  func animateMenu(state:Bool, animated:Bool, completion:((Bool) -> Void)?) {
    let show = state
    
    if state {
      self.headerView.transform = CGAffineTransformMakeTranslation(0, -self.headerView.bounds.height)
      self.tableView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0.0, self.view.bounds.height), 0.9, 0.9);
      backdropImageView.alpha = 0
      
      screenshotImageView.image = backdrop
      backdropImageView.image = backdrop?.applyBlurWithRadius(20, tintColor: UIColor.clearColor(), saturationDeltaFactor: 1.0, maskImage: nil)
    }
    
    let fase1:()->() = {
      self.tableView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0.0, 0.0), 0.9, 0.9)
      self.backdropImageView.alpha = 0.25
    }
    let fase2:()->() = {
      if show {
        self.tableView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0.0, 0.0), 1.0, 1.0)
        self.backdropImageView.alpha = 1
      } else {
        self.tableView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0.0, self.view.bounds.height), 0.9, 0.9)
        self.backdropImageView.alpha = 0
      }
    }
    let header:()->() = {
      self.headerView.transform = show ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, -self.headerView.bounds.height)
    }
    
    if animated {
      UIView.animateKeyframesWithDuration(PickerAnimationDuration, delay: 0,
        options: UIViewKeyframeAnimationOptions.CalculationModeCubic | UIViewKeyframeAnimationOptions.AllowUserInteraction,
        animations: {
        UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.5, animations: fase1)
        UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: fase2)
      }, completion: completion)
      UIView.animateWithDuration(PickerAnimationDuration, animations: header) {
        if $0 {
          if !show {
            self.headerView.transform = CGAffineTransformMakeTranslation(0, -self.headerView.bounds.height)
            self.backdropImageView.hidden = true
          }
          self.tableView.contentOffset.y = 0
          self.tableView.transform = CGAffineTransformIdentity
          self.isDismissing = false
        }
      }
    } else {
      header()
      fase1()
      fase2()
      if let c = completion {
        c(true)
      }
    }
  }
  
  /// MARK: Table View Delegation
  
  func selectRow() {
    
    var indexPath:NSIndexPath?
    if let station = currentStation {
      if let index = findIndex(mostUsed, station) {
        indexPath = NSIndexPath(forRow: index, inSection: 0)
      } else {
        if let index = findIndex(stations, station) {
          indexPath = NSIndexPath(forRow: index, inSection: 2)
        }
      }
      if let ix = indexPath {
        if tableView.cellForRowAtIndexPath(ix) != nil {
          tableView.selectRowAtIndexPath(ix, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        }
      }
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var station:Station
    
    if indexPath.section == 0 {
      station = mostUsed[indexPath.row]
    } else if indexPath.section == 1 {
      station = TreinTicker.sharedInstance.closeStations[indexPath.row]
    } else if indexPath.section == 2 {
      station = stations[indexPath.row]
    } else {
      station = stationsFound()[indexPath.row]
    }
    
    var cell:PickerCellView = self.tableView.dequeueReusableCellWithIdentifier("cell") as PickerCellView
    
    cell.station = station
    return cell
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 4
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return !isEditing() ? mostUsed.count : 0
    } else if section == 1 {
      return !isEditing() ? TreinTicker.sharedInstance.closeStations.count : 0
    } else if section == 2 {
      return !isEditing() ? stations.count : 0
    } else {
      return isEditing() ? stationsFound().count : 0
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let cb = selectStationHandler {
      if indexPath.section == 0 {
        currentStation = mostUsed[indexPath.row]
      } else if indexPath.section == 1 {
        currentStation = TreinTicker.sharedInstance.closeStations[indexPath.row]
      } else if indexPath.section == 2 {
        currentStation = stations[indexPath.row]
      } else {
        currentStation = stationsFound()[indexPath.row]
      }
      searchView.resignFirstResponder()
      searchView.text = ""
    }
    dismissPicker()
  }
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return isEditing() ? "" : (mostUsed.count == 0 ? "" : "Meest gebruikt")
    } else if section == 1 {
      return isEditing() ? "" : (TreinTicker.sharedInstance.closeStations.count == 0 ? "" : "Dichtstebij")
    } else {
      return isEditing() ? "" : (stations.count == 0 ? "" : "A-Z")
    }
  }
  
  func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    
    let headerView = view as UITableViewHeaderFooterView
    headerView.textLabel.font = UIFont(name: "Aktiv-Light", size: 16.0)
    headerView.textLabel.textColor = UIColor.whiteColor()
    headerView.contentView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
  }
  
  func textFieldDidBeginEditing(textField: UITextField) {
    UIView.animateWithDuration(0.2) {
      self.leftMarginSearchField.constant = -self.pickerTitle.bounds.width
      self.pickerTitle.alpha = 0
      self.view.layoutIfNeeded()
    }
  }
  
  func textFieldDidEndEditing(textField: UITextField) {
    UIView.animateWithDuration(0.2) {
      self.leftMarginSearchField.constant = 16
      self.pickerTitle.alpha = 1
      self.view.layoutIfNeeded()
    }
  }
  
  func textFieldDidChange(textField:UITextField) {
    tableView.reloadData()
  }
  
  func stationsFound() -> [Station] {
    return stations.filter {
      ($0.name.lang.lowercaseString as NSString).containsString(self.searchView.text.lowercaseString)
    }
  }
  
  func isEditing() -> Bool {
    return searchView.text != ""
  }
  
  /// MARK: ScrollView Delegation
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    tableView.alpha = 1
    pulldownIcon.alpha = 0
    pulldownIcon.transform = CGAffineTransformIdentity
    if scrollView.contentOffset.y < 0 && !isDismissing {
      headerView.transform = CGAffineTransformMakeTranslation(0, scrollView.contentOffset.y/2)
      if scrollView.contentOffset.y < -50 {
        willDismiss = true
        scrollView.transform = CGAffineTransformMakeTranslation(0, 10)
        let progress = min(((-scrollView.contentOffset.y - 50) / 50)/4, 0.5)
        let scale = 1 - (0.25 * progress)
        tableView.transform = CGAffineTransformMakeScale(scale, scale)
        tableView.alpha = 1 - progress
        pulldownIcon.alpha = min(progress * 10, 1)
        let scalePulldown = min(progress * 10, 1)
        pulldownIcon.transform = CGAffineTransformMakeScale(scalePulldown, scalePulldown)
      } else {
        willDismiss = false
        scrollView.transform = CGAffineTransformIdentity
      }
    }
  }
  
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if willDismiss {
      self.isDismissing = true
      dismissPicker()
    }
  }
  
  /// MARK: Button Delegation
  
  @IBAction func closeButton(sender: AnyObject) {
    if searchView.isFirstResponder() {
      searchView.text = ""
      searchView.endEditing(true)
      tableView.reloadData()
    } else {
      dismissPicker()
    }
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  func dismissPicker() {
    searchView.text = "" 
    searchView.endEditing(true)
    searchView.resignFirstResponder()
    
    if let cb = selectStationHandler {
      cb(currentStation)
      willDismiss = false
    }
    
    animateMenu(false, animated: true) { _ in
      self.performSegueWithIdentifier("unwindPicker", sender: self)
      //self.dismissViewControllerAnimated(true, completion: nil)
      return;
    }
  }
  
}
