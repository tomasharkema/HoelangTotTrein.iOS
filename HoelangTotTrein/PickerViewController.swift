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
            selectRow()
        }
    }
    
    var selectStationHandler:SelectStationHandler!
    var mostUsed:Array<Station> {
        return MostUsed.getListByVisited()
    }
    var currentLocation:CLLocation?
    var stations:Array<Station> {
        let mostUsed =  self.mostUsed
        let stations = TreinTicker.sharedInstance.stations.filter { [weak self] station in
            return !mostUsed.contains(station)
        }
        if let c = currentLocation {
            return Station.sortStationsOnLocation(stations, loc: c, sorter: <)
        } else {
            return stations
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor()
        locationManager.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        selectRow()
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
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        locationManager.stopUpdatingLocation()
        
        //currentLocation = locations.first as? CLLocation
        
        tableView.reloadData()
        selectRow()
    }
    
}
