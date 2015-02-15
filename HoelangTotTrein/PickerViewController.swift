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

class PickerViewController : UITableViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var pickerTitle: UINavigationItem!
    
    var locationManager:CLLocationManager = CLLocationManager()
    
    var mode:StationType! {
        didSet {
            pickerTitle?.title = (mode == StationType.From) ? "Van" : "Naar"
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
        
        tableView.reloadData()
        selectRow()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor()
        locationManager.delegate = self
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let station = (indexPath.section) == 0 ? mostUsed[indexPath.row] : stations[indexPath.row]
        
        var cell:PickerCellView = self.tableView.dequeueReusableCellWithIdentifier("cell") as PickerCellView
        
        cell.station = station
        
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return mostUsed.count
        } else {
            return stations.count
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cb = selectStationHandler {
            cb(indexPath.section == 0 ? mostUsed[indexPath.row] : stations[indexPath.row])
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Meest gebruikt" : ""
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        locationManager.stopUpdatingLocation()
        
        currentLocation = locations.first as? CLLocation
        
        reload()
    }
    
}
