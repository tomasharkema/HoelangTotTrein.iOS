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
    
    var locationManager:CLLocationManager = CLLocationManager()
    
    var mode:StationType!
    
    var currentStation:Station! {
        didSet {
            reload()
        }
    }
    
    var selectStationHandler:SelectStationHandler!
    
    var currentLocation:CLLocation?
    
    var mostUsed:Array<Station> = []
    var stations:Array<Station> = []
    
    func reload() {
        self.mostUsed = MostUsed.getListByVisited()
        let stations = TreinTicker.sharedInstance.stations.filter { [weak self] station in
            return (self?.mostUsed.contains(station) != nil)
        }
        if let c = currentLocation {
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) { [weak self] _ in
                self?.stations = Station.sortStationsOnLocation(stations, loc: c, sorter: <)
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
      
        tableView.backgroundColor = UIColor.blackColor()
        locationManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
      
        pickerTitle.text = (mode == StationType.From) ? "Van" : "Naar"
      
        searchView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reload()
        locationManager.startUpdatingLocation()
    }
    
    func selectRow() {
        
        var indexPath:NSIndexPath
        
        if let index = findIndex(mostUsed, currentStation!) {
            indexPath = NSIndexPath(forRow: index, inSection: 0)
        } else {
            let index = findIndex(stations, currentStation)
            indexPath = NSIndexPath(forRow: index!, inSection: 1)
        }
        
        tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let station = (indexPath.section) == 0 ? mostUsed[indexPath.row] : stations[indexPath.row]
        
        var cell:PickerCellView = self.tableView.dequeueReusableCellWithIdentifier("cell") as PickerCellView
        
        cell.station = station
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return mostUsed.count
        } else {
            return stations.count
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cb = selectStationHandler {
            cb(indexPath.section == 0 ? mostUsed[indexPath.row] : stations[indexPath.row])
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Meest gebruikt" : (currentLocation == nil ? "A-B" : "Dichtstebij")
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
        self.leftMarginSearchField.constant = 0
        self.view.layoutIfNeeded()
      }
    }
  
    @IBAction func closeButton(sender: AnyObject) {
      dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
      return UIStatusBarStyle.LightContent
    }
  
}
