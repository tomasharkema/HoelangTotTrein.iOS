//
//  UIView+Screenshot.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 22-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

extension UIView {
  func screenShot() -> UIImage {
    UIGraphicsBeginImageContext(self.bounds.size)
    self.drawViewHierarchyInRect(self.frame, afterScreenUpdates:true)
    var image:UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
  }
}
