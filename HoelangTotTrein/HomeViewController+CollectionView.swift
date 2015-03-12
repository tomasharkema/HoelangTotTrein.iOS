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
    startTimerForMiddleVisibleCell()
  }
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let count = TreinTicker.sharedInstance.getUpcomingAdvices().count
    advicesIndicator.numberOfPages = count
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
}

class AdviceCollectionviewCell : UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
  
  var timer:NSTimer?
  
  var progress:CGFloat = 1 {
    didSet {
      let scale = abs(progress)
      transform = CGAffineTransformMakeScale(scale, scale)
    }
  }
  
  @IBOutlet weak var timeToGoLabel: UILabel!
  @IBOutlet weak var spoor: UILabel!
  @IBOutlet weak var to: UILabel!
  @IBOutlet weak var from: UILabel!
  @IBOutlet weak var vertagingLabel: UILabel!
  @IBOutlet weak var adviceDetailTableView: UITableView!
  
  var advice: Advice? {
    didSet {

      timeToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().string()
      spoor.text = advice?.firstStop()?.spoor
      
      if let a = advice {
        let fromTime = a.vertrek.getFormattedString()
        let toTime = a.aankomst.getFormattedString()
        from.text = "\(a.firstStop()!.name) - \(fromTime)"
        to.text = "\(a.lastStop()!.name) - \(toTime)"
    
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
    timeToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().string()
    timeToGoLabel.textColor = self.advice?.vertrek.actual.timeIntervalSinceNow < 60 ? UIColor.redThemeColor() : UIColor.whiteColor()
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count = advice?.reisDeel.count ?? 0
    return count == 1 ? 0 : count
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
  @IBOutlet weak var toStation: UILabel!
  @IBOutlet weak var toPlatform: UILabel!
  @IBOutlet weak var fromPlatform: UILabel!
  @IBOutlet weak var trainType: UILabel!
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    selectionStyle = UITableViewCellSelectionStyle.None
    backgroundView = nil
    backgroundColor = UIColor.clearColor()
  }
  
  var reisDeel:ReisDeel? {
    didSet {
      if let deel = reisDeel {
        let from = deel.stops.first
        let to = deel.stops.last
        
        fromStation.text = from?.name ?? ""
        fromPlatform.text = from?.spoor
        
        toStation.text = to?.name
        toPlatform.text = to?.spoor
      }
    }
  }
}
