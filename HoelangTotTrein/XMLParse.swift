//
//  XMLParse.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Alamofire

extension Request {
    class func XMLResponseSerializer() -> Serializer {
        return { (request, response, data) in
            if data == nil {
                return (nil, nil)
            }
            
            var error: NSError?
          
            let XML = AEXMLDocument(xmlData: data!, error: &error)
          
            return (XML, error)
        }
    }
    
    func responseXMLDocument(completionHandler: (NSURLRequest, NSHTTPURLResponse?, AEXMLDocument?, NSError?) -> Void) -> Self {
        return response(serializer: Request.XMLResponseSerializer(), completionHandler: { (request, response, XML, error) in
            if let x = XML as? AEXMLDocument {
                completionHandler(request, response, x as AEXMLDocument, error)
            } else {
                println(response, error)
            }
        })
    }
}