//
//  UIImage+BlurSequence.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 22-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import GPUImage

extension UIImage {
  
  func generateBlurSequence(steps:Int, maxBlur:Int, reverse:Bool) -> [UIImage] {
    let image = self.copy() as UIImage
    var images:[UIImage] = []
    let stepsAdjusted = steps / 2
    
    for var index = 0; index < stepsAdjusted; ++index {
      let blurStep = CGFloat(Float(maxBlur) * pow(Float(index)/Float(stepsAdjusted), 4))
      images.append(image.blur(blurStep))
    }
    
    if reverse {
      images = images.reverse()
    }
    
    return images
  }
  
  func blur(blur:CGFloat) -> UIImage {
    let blurEffect = GPUImageGaussianBlurFilter()
    blurEffect.blurRadiusInPixels = blur
    return blurEffect.imageByFilteringImage(self)
  }
  
}