//
//  XMLParse.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Alamofire
import Ono

extension Request {
    class func XMLResponseSerializer() -> Serializer {
        return { (request, response, data) in
            if data == nil {
                return (nil, nil)
            }
            
            var XMLSerializationError: NSError?
            let XML = ONOXMLDocument(data: data, error:&XMLSerializationError)
            
            return (XML, XMLSerializationError)
        }
    }
    
    func responseXMLDocument(completionHandler: (NSURLRequest, NSHTTPURLResponse?, ONOXMLDocument?, NSError?) -> Void) -> Self {
        return response(serializer: Request.XMLResponseSerializer(), completionHandler: { (request, response, XML, error) in
            if let x = XML {
                completionHandler(request, response, x as ONOXMLDocument, error)
            } else {
                println(response, error)
            }
        })
    }
}