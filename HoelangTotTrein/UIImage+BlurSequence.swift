//
//  UIImage+BlurSequence.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 22-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

extension UIImage {
  
  func generateBlurSequence(steps:Int, maxBlur:Int, reverse:Bool) -> [UIImage] {
    let image = self.copy() as UIImage
    var images:[UIImage] = []
    let stepsAdjusted = steps / 4
    
    for var index = 0; index < stepsAdjusted; ++index {
      let blurStep = CGFloat(Float(maxBlur) * (Float(index)/Float(stepsAdjusted)))
      
      //let blurredImage = image.applyBlurWithRadius(blurStep, tintColor: nil, saturationDeltaFactor: 2.0, maskImage: nil)
      let blurImage = GPUImageiOSBlurFilter()
      
      let blurredImage = GPUImagePicture(image)
      
      images.append(blurredImage)
    }
    
    if reverse {
      images = images.reverse()
    }
    
    return images
  }
  
}