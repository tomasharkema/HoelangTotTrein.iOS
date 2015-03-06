//
//  PickerSegue.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 26-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

class PickerSegue: UIStoryboardSegue {
  
  override func perform() {
    let source = sourceViewController as UIViewController
    let dest = destinationViewController as UIViewController
    
    source.presentViewController(dest, animated: false, completion: nil)
  }
  
}

class UnwindPickerSegue: UIStoryboardSegue {
  
  override func perform() {
    
    let source = sourceViewController as UIViewController
    let dest = destinationViewController as UIViewController
    
//    dest.view.addSubview(source.view)
//    
//    source.dismissViewControllerAnimated(false, completion:{
//      source.view.removeFromSuperview()
//    })
    
  }
}
