//
//  TreinTicker.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 11-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import Alamofire

typealias TickerHandler = (MMSS) -> Void
typealias AdviceChangedHandler = (from:String, to:String, fromTime:String, toTime:String) -> Void

class TreinTicker: NSObject {
    
    var currentAdviceRequest:Request!
    var currentAdivce:Advice! {
        didSet {
            if (adviceChangedHandler != nil) {
                let from = currentAdivce.adviceRequest.from
                let to = currentAdivce.adviceRequest.to
                
                adviceChangedHandler(from:from.naam.lang, to: to.naam.lang, fromTime: currentAdivce.vertrek.getFormattedString(), toTime: currentAdivce.aankomst.getFormattedString())
            }
        }
    }
    
    var heartBeat:NSTimer!
    var minuteTicker:Int = 0
    private var advices:Array<Advice> = []
    
    var adviceRequest:AdviceRequest! {
        didSet {
            changeRequest()
            minuteTicker = 0
        }
    }
    
    var tickerHandler:TickerHandler!
    var adviceChangedHandler:AdviceChangedHandler!
    
    func start() {
        heartBeat = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timerCallback"), userInfo: nil, repeats: true)
    }
    
    func stop() {
        if (heartBeat != nil) {
            heartBeat.invalidate()
            heartBeat = nil;
        }
    }
    
    func changeRequest() {
        if currentAdviceRequest != nil {
            currentAdviceRequest.cancel()
        }
        
        currentAdviceRequest = API().getAdvice(adviceRequest) { [weak self] advices in
            let a:Array<Advice> = advices;
            self?.advices = a
        }
    }
    
    func getCurrentAdvice() -> Advice? {
        return advices.filter {
            $0.vertrek.actual.timeIntervalSinceNow > 0
         }.first
    }
    
    func timerCallback() {
        if (tickerHandler != nil && adviceRequest != nil) {
            if let currentAdv = getCurrentAdvice() {
                if let currentAdvice = self.currentAdivce {
                    if (self.currentAdivce != currentAdv) {
                        self.currentAdivce = currentAdv
                    }
                } else {
                    self.currentAdivce = currentAdv
                }
                
                
                tickerHandler(currentAdivce.vertrek.actual.toMMSS())
            }
        }
        
        if (minuteTicker > 30) {
            if (currentAdivce != nil) {
                changeRequest();
            }
            minuteTicker = 0
        }
        minuteTicker++;
    }
}
