//
//  HomeViewController+CollectionView.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 26-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

let AdviceReuseIdentifier = "AdviceReuseIdentifier"

extension HomeViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let count = TreinTicker.sharedInstance.getUpcomingAdvices().count
    return count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AdviceReuseIdentifier, forIndexPath: indexPath) as AdviceCollectionviewCell
    cell.advice = TreinTicker.sharedInstance.getUpcomingAdvices()[indexPath.row]
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return CGSize(width: self.advicesCollectionView.bounds.width, height: self.advicesCollectionView.bounds.height - 10)
  }
  
  func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    (cell as AdviceCollectionviewCell).startCounting()
  }
  
  func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    (cell as AdviceCollectionviewCell).stopCounting()
  }
  
}

class AdviceCollectionviewCell : UICollectionViewCell {
  
  var timer:NSTimer?
  
  @IBOutlet weak var timeToGoLabel: UILabel!
  @IBOutlet weak var spoor: UILabel!
  @IBOutlet weak var to: UILabel!
  @IBOutlet weak var from: UILabel!
  
  var advice: Advice? {
    didSet {
      timeToGoLabel.text = advice?.vertrek.actual.toMMSSFromNow().string()
      spoor.text = advice?.firstStop()?.spoor
      from.text = advice?.firstStop()?.name
      to.text = advice?.lastStop()?.name
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
