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
    @IBOutlet weak var vertagingLabel: UILabel!
    @IBOutlet weak var stationPicker: UIPickerView!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    
    @IBOutlet weak var fromStationLabel: UILabel!
    @IBOutlet weak var toStationLabel: UILabel!
    
    @IBOutlet weak var spoorLabel: UILabel!
    @IBOutlet weak var legPhraseLeftTextView: UITextView!
    @IBOutlet weak var legPhraseRightTextView: UITextView!
    
    @IBOutlet weak var pickerContainerView: UIView!
    
    @IBOutlet weak var alertTextView: UITextView!
    
    private var selectionState:StationType = .From {
        didSet {
            if let i = find(TreinTicker.sharedInstance.stations, selectionState == .From ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to) {
                pick(TreinTicker.sharedInstance.stations[i])
                selectRow()
            }
        }
    }
    
    private func selectRow() {
        if let i = find(TreinTicker.sharedInstance.stations, selectionState == .From ? TreinTicker.sharedInstance.from : TreinTicker.sharedInstance.to!) {
            stationPicker.selectRow(i, inComponent: 0, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            self?.legPhraseLeftTextView.textColor = UIColor.secundairThemeColor()
            self?.legPhraseLeftTextView.textAlignment = NSTextAlignment.Right
            
            self?.legPhraseRightTextView.text = advice.legPhraseRight()
            self?.legPhraseRightTextView.textColor = UIColor.secundairThemeColor()
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
        
        TreinTicker.sharedInstance.stationChangedHandler = { [weak self] s in
            self?.stationPicker.reloadAllComponents()
            self?.selectRow()
        }
        
        TreinTicker.sharedInstance.fromToChanged = { [weak self] from, to in
            self?.toButton.setTitle(to?.name.lang, forState: UIControlState.Normal)
            self?.fromButton.setTitle(from?.name.lang, forState: UIControlState.Normal)
            self?.selectRow()
        }
        
        TreinTicker.sharedInstance.start()
        
        stationPicker.dataSource = self
        stationPicker.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setPickerState(false, animate: false)
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
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return TreinTicker.sharedInstance.stations[row].name.lang
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TreinTicker.sharedInstance.stations.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if selectionState == .From {
            TreinTicker.sharedInstance.originalFrom = TreinTicker.sharedInstance.stations[row]
            TreinTicker.sharedInstance.from = TreinTicker.sharedInstance.stations[row]
        } else {
            TreinTicker.sharedInstance.to = TreinTicker.sharedInstance.stations[row]
        }
    }
    
    func setPickerState(state:Bool, animate:Bool = true) {
        
        let animateBlock:() -> Void = { [weak self] _ in
            let height = self?.pickerContainerView.bounds.height
            self?.pickerContainerView.transform = state ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, height!)
        }
        
        if animate {
            UIView.animateWithDuration(0.2, animateBlock)
        } else {
            animateBlock()
        }
    }
    
    @IBAction func fromButton(sender: AnyObject) {
        setPickerState(true)
        selectionState = .From
    }
    
    @IBAction func toButton(sender: AnyObject) {
        setPickerState(true)
        selectionState = .To
    }
    
    @IBAction func locButton(sender: AnyObject) {
        TreinTicker.sharedInstance.fromCurrentLocation()
        setPickerState(false)
    }
    
    @IBAction func pickerGereedButton(sender: AnyObject) {
        setPickerState(false)
    }
    
    @IBAction func swapLocations(sender: AnyObject) {
        setPickerState(false)
        TreinTicker.sharedInstance.switchAdviceRequest()
        TreinTicker.sharedInstance.saveOriginalFrom()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
