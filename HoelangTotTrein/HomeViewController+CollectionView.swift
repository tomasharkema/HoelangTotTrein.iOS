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
  
  func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    let c = cell as AdviceCollectionviewCell
    c.startCounting()
  }
  
  func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    (cell as AdviceCollectionviewCell).stopCounting()
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
      let cell = cellObj as UICollectionViewCell
      let offset = offsetForCell(cell, contentOffset: Int(contentOffset.y))
      
      let progress = 1 - abs(CGFloat(offset) / cell.bounds.height)/4
      
      let scale = abs(progress)
      
      cell.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
  }
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    let visibleCells = advicesCollectionView.visibleCells()
    if let cell = visibleCells.first as? AdviceCollectionviewCell {
      let advice = cell.advice
      TreinTicker.sharedInstance.adviceOffset = advice?.vertrek.actual
      advicesIndicator.currentPage = advicesCollectionView.indexPathForCell(cell)?.row ?? 0
    }
  }
  
}

class AdviceCollectionviewCell : UICollectionViewCell {
  
  var timer:NSTimer?
  
  @IBOutlet weak var timeToGoLabel: UILabel!
  @IBOutlet weak var spoor: UILabel!
  @IBOutlet weak var to: UILabel!
  @IBOutlet weak var from: UILabel!
  @IBOutlet weak var vertagingLabel: UILabel!
  @IBOutlet weak var alertTextView: UITextView!
  @IBOutlet weak var legPhraseLeftTextView: UITextView!
  @IBOutlet weak var legPhraseRightTextView: UITextView!
  
  var advice: Advice? {
    didSet {

      timeToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().string()
      spoor.text = advice?.firstStop()?.spoor
      
      if let a = advice {
        let fromTime = a.vertrek.getFormattedString()
        let toTime = a.aankomst.getFormattedString()
        from.text = "\(a.firstStop()!.name) - \(fromTime)"
        to.text = "\(a.lastStop()!.name) - \(toTime)"
      }
      
      legPhraseLeftTextView.text = advice?.legPhraseLeft()
      legPhraseLeftTextView.textColor = UIColor.secundairGreyColor()
      legPhraseLeftTextView.textAlignment = NSTextAlignment.Right
      
      legPhraseRightTextView.text = advice?.legPhraseRight()
      legPhraseRightTextView.textColor = UIColor.secundairGreyColor()
      legPhraseRightTextView.textAlignment = NSTextAlignment.Left
      
      if let vertraging = advice?.vertrekVertraging {
        vertagingLabel.text = vertraging
        vertagingLabel.hidden = false
      } else {
        vertagingLabel.hidden = true
      }
      
      if let melding = advice?.melding {
        alertTextView.text = melding.text
        alertTextView.hidden = false
      } else {
        alertTextView.insertText("")
        alertTextView.hidden = true
      }
    }
  }
  
  func startCounting() {
    timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: true)
  }
  
  func stopCounting() {
    if timer != nil{
      timer?.invalidate()
      timer = nil
    }
  }
  
  
  func updateUI() {
    timeToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().string()
  }
  
}
