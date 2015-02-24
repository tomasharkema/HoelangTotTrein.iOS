 //
//  XML+Format.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 14-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Ono

extension ONOXMLElement {
    
    func getElement(tag:String) -> ONOXMLElement! {
        return self.childrenWithTag(tag).first as? ONOXMLElement
    }
    
    func string(tagName tag: String) -> String? {
        return getElement(tag)?.stringValue()
    }
    
    func int(tagName tag: String) -> Int? {
      if let str = string(tagName: tag) {
        return NSString(string: str).integerValue
      }
      return nil
    }
    
    func double(tagName tag: String) -> Double? {
      if let str = string(tagName: tag) {
        return NSString(string: str).doubleValue
      }
      return nil
    }
    
    func date(tagName tag: String) -> NSDate? {
        return getElement(tag)?.dateValue()
    }
}      