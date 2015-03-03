//
//  API.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 13-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Alamofire
import Ono

struct AdviceRequest {
    let from:Station
    let to:Station
}

class API: NSObject {
    
    private func authenticatedRequest(method:Alamofire.Method, url:String, parameters:[String: AnyObject]? = nil) -> Request {
        let request = Alamofire.request(method, url, parameters: parameters).authenticate(user: "tomas@harkema.in", password: "kh8ZilSuswjYn4euawWLtWlgSEPj0-fVbnW0nOlxrHKmp05gSDh-Sw")
        return request
    }
    
    func getStations(aHandler:(Array<Station>) -> Void) -> Request {
        let request = authenticatedRequest(Alamofire.Method.GET, url:"http://webservices.ns.nl/ns-api-stations-v2")
            .responseXMLDocument { (_, _, string, _) in
                if let object = string {
                    if let stationsData = object.rootElement?.children {
                        let stations:[Station] = stationsData
                            .map { Station(obj: $0 as ONOXMLElement) }
                            .filter { $0.land == "NL" }
                        aHandler(stations)
                    }
                }
        }
        
        return request
    }
    
    func getAdvice(adviceRequest:AdviceRequest, aHandler:(advices:Array<Advice>) -> Void) -> Request {
        let request = authenticatedRequest(Alamofire.Method.GET,
            url:"http://webservices.ns.nl/ns-api-treinplanner",
            parameters: ["fromStation":adviceRequest.from.code, "toStation":adviceRequest.to.code])
            
            .responseXMLDocument { _, _, string, _ in
                if let object = string {
                    if let travelData = object.rootElement?.children {
                        let advices:Array<Advice> = travelData.map { Advice(obj: $0 as ONOXMLElement, adviceRequest: adviceRequest) }
                        aHandler(advices: advices)
                    }
                }
        }
        
        return request
    }
}