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

class PickerViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UITextFieldDelegate {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var pickerTitle: UILabel!
  @IBOutlet weak var searchView: UITextField!
  @IBOutlet weak var leftMarginSearchField: NSLayoutConstraint!
  
  @IBOutlet weak var headerView: UIView!
  
  var blurEffectView:UIVisualEffectView!
  
  var locationManager:CLLocationManager = CLLocationManager()
  
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
  
  var currentLocation:CLLocation?
  
  var mostUsed:Array<Station> = []
  var stations:Array<Station> = []
  var closeStations:Array<Station> = []
  
  func reload() {
    self.mostUsed = MostUsed.getListByVisited().slice(5)
    let stations = TreinTicker.sharedInstance.stations.filter { [weak self] station in
      return (self?.mostUsed.contains(station) != nil)
    }
    if let c = currentLocation {
      let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
      dispatch_async(dispatch_get_global_queue(priority, 0)) { [weak self] _ in
        self?.closeStations = Station.sortStationsOnLocation(stations, loc: c, sorter: <, number:5)
        dispatch_async(dispatch_get_main_queue()) { [weak self] _ in
          self?.tableView.reloadData()
          self?.selectRow()
        }
      }
      return
    } else {
      self.stations = stations
    }
    
    if let tv = tableView {
      tv.reloadData()
      selectRow()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager.delegate = self
    tableView.backgroundColor = UIColor.clearColor()
    tableView.backgroundView = nil
    tableView.delegate = self
    tableView.dataSource = self
    
    let blur = UIBlurEffect(style: .Dark)
    blurEffectView = UIVisualEffectView(effect: blur)
    blurEffectView.frame = view.frame
    blurEffectView.alpha = 0
    view.insertSubview(blurEffectView, belowSubview: headerView)
    
    setState(false, completion: nil)
    
    pickerTitle.text = (mode == StationType.From) ? "Van" : "Naar"
    
    searchView.delegate = self
    searchView.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)
    searchView.attributedPlaceholder = NSAttributedString(string: "Zoeken...", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(0.3)])
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    reload()
    locationManager.startUpdatingLocation()
  }
  
  var showState:Bool = false
  
  func setState(state: Bool, completion: ((Bool) -> Void)?) {
    showState = state
    let animation: () -> Void = {
      self.blurEffectView.alpha = self.showState ? 1 : 0
      //self.view.alpha = self.showState ? 1 : 0
      
      self.tableView.transform = self.showState ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, self.view.bounds.height)
      self.headerView.transform = self.showState ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, -self.headerView.bounds.height)
    }
    
    UIView.animateWithDuration(0.25, animations: animation, completion: completion)
  }
  
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
      station = closeStations[indexPath.row]
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
      return !isEditing() ? closeStations.count : 0
    } else if section == 2 {
      return !isEditing() ? stations.count : 0
    } else {
      return isEditing() ? stationsFound().count : 0
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let cb = selectStationHandler {
      if indexPath.section == 0 {
        cb(mostUsed[indexPath.row])
      } else if indexPath.section == 1 {
        cb(closeStations[indexPath.row])
      } else if indexPath.section == 2 {
        cb(stations[indexPath.row])
      } else {
        cb(stationsFound()[indexPath.row])
      }
      searchView.resignFirstResponder()
      searchView.text = ""
    }
    
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return isEditing() ? "" : "Meest gebruikt"
    } else if section == 1 {
      return isEditing() ? "" : "Dichtstebij"
    } else {
      return isEditing() ? "" : "A-Z"
    }
  }
  
  func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    
    let headerView = view as UITableViewHeaderFooterView
    headerView.textLabel.font = UIFont(name: "Aktiv-Light", size: 16.0)
    headerView.textLabel.textColor = UIColor.whiteColor()
    headerView.contentView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    locationManager.stopUpdatingLocation()
    
    currentLocation = locations.first as? CLLocation
    
    reload()
  }
  
  func textFieldDidBeginEditing(textField: UITextField) {
    UIView.animateWithDuration(0.2) {
      self.leftMarginSearchField.constant = -self.pickerTitle.bounds.width
      self.view.layoutIfNeeded()
    }
  }
  
  func textFieldDidEndEditing(textField: UITextField) {
    UIView.animateWithDuration(0.2) {
      self.leftMarginSearchField.constant = 16
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
  
  @IBAction func closeButton(sender: AnyObject) {
    if searchView.isFirstResponder() {
      searchView.text = ""
      searchView.endEditing(true)
      tableView.reloadData()
    } else {
      if let cb = selectStationHandler {
        searchView.resignFirstResponder()
        cb(currentStation)
      }
    }
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
}
