//
//  HomeViewController+CollectionView.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 26-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

let AdviceReuseIdentifier = "AdviceReuseIdentifier"

extension HomeViewController : UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    startTimerForMiddleVisibleCell()
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    if let timer = cellTimer {
      timer.invalidate()
      cellTimer = nil
    }
  }
  
  func reload() {
    advicesCollectionView.reloadData()
    let index = TreinTicker.sharedInstance.getAdviceOffset()
    if index > -1 {
      //advicesCollectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
    }
    dispatch_after(2, dispatch_get_main_queue()) {
      self.startTimerForMiddleVisibleCell()
    }
  }
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let count = TreinTicker.sharedInstance.getUpcomingAdvices().count
    advicesIndicator.numberOfPages = count
    activityIndicator.hidden = count != 0
    return count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AdviceReuseIdentifier, forIndexPath: indexPath) as AdviceCollectionviewCell
    cell.advice = TreinTicker.sharedInstance.getUpcomingAdvices()[indexPath.row]
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return CGSize(width: self.advicesCollectionView.bounds.width, height: self.advicesCollectionView.bounds.height)
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
    return 0
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
    return 0
  }
  
  func offsetForCell(cell: UICollectionViewCell, contentOffset:Int) -> Int {
    let indexPath:NSIndexPath = advicesCollectionView.indexPathForCell(cell)!
    let offset = contentOffset - Int(Int(cell.bounds.height) * Int(indexPath.row))
    return offset
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let cells = advicesCollectionView.visibleCells()
    let contentOffset = scrollView.contentOffset
    for cellObj in cells {
      let cell = cellObj as AdviceCollectionviewCell
      let offset = offsetForCell(cell, contentOffset: Int(contentOffset.y))
      
      let progress = 1 - abs(CGFloat(offset) / cell.bounds.height)/2
      
      cell.progress = progress
    }
  }
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    if let cell = getMiddleVisibleCell() {
      let advice = cell.advice
      TreinTicker.sharedInstance.adviceOffset = advice?.vertrek.actual
      advicesIndicator.currentPage = advicesCollectionView.indexPathForCell(cell)?.row ?? 0
    }
    
    startTimerForMiddleVisibleCell()
  }
  
  func getMiddleVisibleCell() -> AdviceCollectionviewCell? {
    let visibleCells = advicesCollectionView.visibleCells()
    for cellObj in visibleCells {
      let cell = cellObj as AdviceCollectionviewCell
      if cell.progress > 0.9 {
        return cell
      }
    }
    return nil;
  }
  
  func startTimerForMiddleVisibleCell() {
    if let cell = getMiddleVisibleCell() {
      if cellTimer != nil {
        cellTimer?.invalidate()
        cellTimer = nil
      }
      cellTimer = cell.startCounting()
    }
  }
  
  func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    startTimerForMiddleVisibleCell()
  }
}

class AdviceCollectionviewCell : UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
  
  var timer:NSTimer?
  
  var progress:CGFloat = 1 {
    didSet {
      let scale = abs(progress)
      transform = CGAffineTransformMakeScale(scale, scale)
    }
  }
  
  @IBOutlet weak var minutesToGoLabel: UILabel!
  @IBOutlet weak var secondsToGoLabel: UILabel!
  @IBOutlet weak var spoor: UILabel!
  @IBOutlet weak var to: UILabel!
  @IBOutlet weak var from: UILabel!
  
  @IBOutlet weak var fromTime: UILabel!
  @IBOutlet weak var toTime: UILabel!
  
  @IBOutlet weak var vertagingLabel: UILabel!
  @IBOutlet weak var adviceDetailTableView: UITableView!
  
  var advice: Advice? {
    didSet {
      minutesToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().minute
      secondsToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().second
      
      spoor.text = advice?.fromPlatform ?? ""
      
      if let a = advice {
        let fromTime = a.vertrek.getFormattedString()
        let toTime = a.aankomst.getFormattedString()
        from.text = "\(a.firstStop()!.name)"
        to.text = "\(a.lastStop()!.name)"
        
        self.toTime.text = toTime
        self.fromTime.text = fromTime
        
        adviceDetailTableView.delegate = self
        adviceDetailTableView.dataSource = self
        adviceDetailTableView.backgroundView = nil
        adviceDetailTableView.backgroundColor = UIColor.clearColor()
        adviceDetailTableView.reloadData()
      }
      
      if let vertraging = advice?.vertrekVertraging {
        vertagingLabel.text = vertraging
        vertagingLabel.hidden = false
      } else {
        vertagingLabel.hidden = true
      }
      
      updateUI()
    }
  }
  
  func startCounting() -> NSTimer {
    return NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: true)
  }
  
  func stopCounting() {
    if timer != nil{
      timer?.invalidate()
      timer = nil
    }
  }
  
  func updateUI() {
    let endDate = advice?.vertrek.actual ?? NSDate()
    if endDate.timeIntervalSinceNow < 60 {
      minutesToGoLabel.text = endDate.toMMSSFromNow().second
      secondsToGoLabel.text = ""
      minutesToGoLabel.textColor = UIColor.redThemeColor()
    } else {
      
      var hourString = ""
      if let hour = endDate.toMMSSFromNow().hour {
        hourString = hour == "0" ? "" : hour + ":"
      }
      
      minutesToGoLabel.text = hourString + "" + endDate.toMMSSFromNow().minute
      secondsToGoLabel.text = endDate.toMMSSFromNow().second
      secondsToGoLabel.textColor = UIColor.whiteColor()
      minutesToGoLabel.textColor = UIColor.whiteColor()
    }
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = advice?.reisDeel.count ?? 0
    return count < 2 ? 0 : count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell:LegDetailCell = tableView.dequeueReusableCellWithIdentifier("legCell") as LegDetailCell
    cell.reisDeel = advice?.reisDeel[indexPath.row]
    cell.backgroundColor = UIColor.clearColor()
    cell.backgroundView = nil
    return cell
  }
  
}

class LegDetailCell : UITableViewCell {
  
  @IBOutlet weak var fromStation: UILabel!
  @IBOutlet weak var fromPlatform: UILabel!
  @IBOutlet weak var fromTime: UILabel!
  
  @IBOutlet weak var toTime: UILabel!
  @IBOutlet weak var toStation: UILabel!
  @IBOutlet weak var toPlatform: UILabel!
  
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    selectionStyle = UITableViewCellSelectionStyle.None
    backgroundView = nil
    backgroundColor = UIColor.clearColor()
  }
  
  var reisDeel:ReisDeel? {
    didSet {
      updateUI()
    }
  }
  
  func updateUI() {
    if let reisDeel = reisDeel {
      let fromStop = reisDeel.stops.first
      let toStop = reisDeel.stops.last
      
      fromStation.text = fromStop?.name
      fromPlatform.text = fromStop?.spoor
      fromTime.text = fromStop?.time?.toHHMM().string()
      
      toStation.text = toStop?.name ?? ""
      toPlatform.text = toStop?.spoor
      toTime.text = toStop?.time?.toHHMM().string()
      
//      fromTime.textColor = isTussenstop ? UIColor.grayColor() : UIColor.lightGreyColor()
//      fromStation.textColor = isTussenstop ? UIColor.grayColor() : UIColor.whiteColor()
    }
  }
}
