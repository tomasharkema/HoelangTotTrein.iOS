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

class HomeViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var timeToGoLabel: UILabel!
    @IBOutlet weak var stationPicker: UIPickerView!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    
    @IBOutlet weak var fromStationLabel: UILabel!
    @IBOutlet weak var toStationLabel: UILabel!
    
    
    private var from:Station! {
        didSet {
            fromButton.setTitle(from.naam.lang, forState: UIControlState.Normal)
            
            NSUserDefaults.standardUserDefaults().setValue(from.code, forKey: "fromKey")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    private var to:Station! {
        didSet {
            toButton.setTitle(to.naam.lang, forState: UIControlState.Normal)
            
            NSUserDefaults.standardUserDefaults().setValue(to.code, forKey: "toKey")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var stations:Array<Station> = []
    
    private let treinTicker:TreinTicker = TreinTicker()
    
    private var selectionState:StationType = .From {
        didSet {
            if let i = find(stations, selectionState == .From ? from : to) {
                pick(stations[i])
                selectRow()
            }
        }
    }
    
    private func selectRow() {
        if let i = find(stations, selectionState == .From ? from : to!) {
            stationPicker.selectRow(i, inComponent: 0, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        API().getStations { [weak self] stations in
            self?.stations = stations
            self?.stationPicker.reloadAllComponents()
            
            let defaults = NSUserDefaults.standardUserDefaults()
            let from = find(stations, defaults.stringForKey("fromKey")) ?? stations.first
            let to = find(stations, defaults.stringForKey("toKey")) ?? stations.first
            
            self?.treinTicker.adviceRequest = AdviceRequest(from: from!, to: to!)
            
            self?.from = from
            self?.to = to
            
            self?.selectRow()
        }
        
        treinTicker.tickerHandler = { [weak self] time in
            let timeToGoLabel = "\(time.minute):\(time.second)"
            self?.timeToGoLabel.text = timeToGoLabel
        };
        
        treinTicker.adviceChangedHandler = { [weak self] (from, to, fromTime, toTime) in
            self?.fromStationLabel.text = "\(from) - \(fromTime)"
            self?.toStationLabel.text = "\(to) - \(toTime)"
        }
        
        treinTicker.start()
        
        stationPicker.dataSource = self
        stationPicker.delegate = self
    }
    
    func pick(station:Station) {
        pick(station, state: selectionState)
    }
    
    func pick(station:Station, state:StationType) {
        if state == .From {
            from = station
        } else {
            to = station
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return self.stations[row].naam.lang
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.stations.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if selectionState == .From {
            from = stations[row]
        } else {
            to = stations[row]
        }
        
        treinTicker.adviceRequest = AdviceRequest(from: from, to: to)
    }
    
    @IBAction func fromButton(sender: AnyObject) {
        selectionState = .From
    }
    
    @IBAction func toButton(sender: AnyObject) {
        selectionState = .To
    }
}
