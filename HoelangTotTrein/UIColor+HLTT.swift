//
//  UIColor+HLTT.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 14-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func primaryGreyColor() -> UIColor {
        return UIColor.blackColor()
    }
  
    class func lightGreyColor() -> UIColor {
        return UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)
    }
    
    class func secundairGreyColor() -> UIColor {
        return UIColor(red: 120/255.0, green: 120/255.0, blue: 120/255.0, alpha: 1)
    }
    
    class func traitaryGreyColor() -> UIColor {
        return UIColor(red: 40/255.0, green: 40/255.0, blue: 40/255.0, alpha: 1)
    }
    
    class func primaryThemeColor() -> UIColor {
        return UIColor(red: 83/255, green: 216/255, blue: 105/255, alpha: 1)
    }
    
    class func secundaryThemeColor() -> UIColor {
        return UIColor(red: 83/255, green: 216/255, blue: 105/255, alpha: 1)
    }
  
    class func redThemeColor() -> UIColor {
      return UIColor(red: 255/255, green: 109/255, blue: 98/255, alpha: 1.0)
    }
}
