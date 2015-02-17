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
        return NSString(string: string(tagName: tag)!).integerValue
    }
    
    func double(tagName tag: String) -> Double? {
        return NSString(string: string(tagName: tag)!).doubleValue
    }
    
    func date(tagName tag: String) -> NSDate? {
        return getElement(tag)?.dateValue()
    }
}      